const { Octokit } = require('@octokit/rest');
const fs = require('fs');
const path = require('path');

// --- Config ---
const RELEASE_DIR = path.resolve(__dirname, '../../release/build');
const PACKAGE_JSON = require('../../package.json');
const RELEASE_JSON = require('../../release/app/package.json');
const VERSION = RELEASE_JSON.version;

function parseRepo(buildConfig, repositoryUrl) {
  if (buildConfig?.publish?.owner && buildConfig?.publish?.repo) {
    return {
      owner: buildConfig.publish.owner,
      repo: buildConfig.publish.repo,
    };
  }
  if (repositoryUrl) {
    const match = repositoryUrl.match(/github\.com[/:]([^/]+)\/([^/.]+)/);
    if (match) {
      return { owner: match[1], repo: match[2].replace(/\.git$/, '') };
    }
  }
  console.error(
    'Cannot determine GitHub owner/repo from package.json.\n' +
      'Set either build.publish.{owner,repo} or repository.url pointing to GitHub.'
  );
  process.exit(1);
}

// Files to skip uploading
const SKIP_PATTERNS = [
  'builder-effective-config.yaml',
  'builder-debug.yml',
  '.DS_Store',
  'Thumbs.db',
  'desktop.ini',
];

const SKIP_EXTENSIONS = [
  // blockmap files are referenced by their parent installer, not uploaded standalone
  // (comment this out if your auto-updater needs them directly)
  // '.blockmap',
];

const SKIP_PREFIXES = ['.'];

function shouldSkip(filename) {
  if (SKIP_PATTERNS.includes(filename)) return true;
  if (SKIP_PREFIXES.some((p) => filename.startsWith(p))) return true;
  if (SKIP_EXTENSIONS.some((e) => filename.endsWith(e))) return true;
  return false;
}

// Determine MIME type for GitHub upload
function mimeType(filename) {
  const ext = path.extname(filename).toLowerCase();
  const types = {
    '.dmg': 'application/x-apple-diskimage',
    '.zip': 'application/zip',
    '.exe': 'application/x-msdownload',
    '.appimage': 'application/x-executable',
    '.deb': 'application/vnd.debian.binary-package',
    '.rpm': 'application/x-rpm',
    '.gz': 'application/gzip',
    '.yml': 'text/yaml',
    '.yaml': 'text/yaml',
    '.blockmap': 'application/octet-stream',
    '.snap': 'application/octet-stream',
  };
  return types[ext] || 'application/octet-stream';
}

function formatDate(date) {
  return date.toISOString().split('T')[0]; // YYYY-MM-DD
}

async function getPreviousTag(octokit, owner, repo, currentTag) {
  try {
    const { data: tags } = await octokit.repos.listTags({
      owner,
      repo,
      per_page: 10,
    });

    // Filter out the current tag in case it was already created
    const previous = tags.find((t) => t.name !== currentTag);
    return previous?.name || null;
  } catch (e) {
    console.warn('Could not fetch previous tags:', e.message);
    return null;
  }
}

async function createOrUpdateTag(octokit, owner, repo, tag, sha) {
  try {
    await octokit.git.getRef({ owner, repo, ref: `tags/${tag}` });
    console.log(`Tag ${tag} already exists.`);
  } catch (e) {
    if (e.status !== 404) throw e;

    // Get the latest commit SHA on the default branch if none provided
    let commitSha = sha;
    if (!commitSha) {
      const { data: repoData } = await octokit.repos.get({ owner, repo });
      const { data: branch } = await octokit.repos.getBranch({
        owner,
        repo,
        branch: repoData.default_branch,
      });
      commitSha = branch.commit.sha;
    }

    console.log(`Creating tag ${tag} at ${commitSha}...`);
    await octokit.git.createRef({
      owner,
      repo,
      ref: `refs/tags/${tag}`,
      sha: commitSha,
    });
    console.log(`✓ Tag ${tag} created.`);
  }
}

function buildReleaseBody(previousTag, currentTag, owner, repo) {
  const currentDate = formatDate(new Date());
  const lines = [];

  lines.push(`**Current Database release**: ${currentDate}`);
  lines.push('');

  if (previousTag) {
    lines.push(
      `**Full Changelog**: https://github.com/${owner}/${repo}/compare/${previousTag}...${currentTag}`
    );
  } else {
    lines.push(
      `**Full Changelog**: https://github.com/${owner}/${repo}/commits/${currentTag}`
    );
  }

  return lines.join('\n');
}

async function getOrCreateRelease(octokit, owner, repo, tag, body) {
  // Try to find existing release for this tag
  try {
    const { data } = await octokit.repos.getReleaseByTag({ owner, repo, tag });
    console.log(`Found existing release: ${data.html_url}`);

    // Update body if release is still a draft
    if (data.draft) {
      await octokit.repos.updateRelease({
        owner,
        repo,
        release_id: data.id,
        body,
      });
      console.log('Updated release body.');
    }

    return data;
  } catch (e) {
    if (e.status !== 404) throw e;
  }

  // Create new draft release linked to the tag
  console.log(`Creating draft release ${tag}...`);
  const { data } = await octokit.repos.createRelease({
    owner,
    repo,
    tag_name: tag,
    name: `v${VERSION}`,
    body,
    draft: true,
    prerelease: false,
  });
  console.log(`✓ Draft release created: ${data.html_url}`);
  return data;
}

async function uploadAsset(octokit, owner, repo, releaseId, filePath) {
  const filename = path.basename(filePath);
  const stat = fs.statSync(filePath);
  const data = fs.readFileSync(filePath);

  console.log(
    `  Uploading ${filename} (${(stat.size / 1024 / 1024).toFixed(1)} MB)...`
  );

  try {
    await octokit.repos.uploadReleaseAsset({
      owner,
      repo,
      release_id: releaseId,
      name: filename,
      data,
      headers: {
        'content-type': mimeType(filename),
        'content-length': stat.size,
      },
    });
    console.log(`  ✓ ${filename}`);
  } catch (e) {
    if (e.status === 422) {
      console.log(`  ⚠ ${filename} already exists, skipping`);
    } else {
      throw e;
    }
  }
}

async function main() {
  const token = process.env.GH_TOKEN || process.env.GITHUB_TOKEN;
  if (!token) {
    console.error(
      'Error: GH_TOKEN or GITHUB_TOKEN environment variable is required'
    );
    process.exit(1);
  }

  const { owner, repo } = parseRepo(
    PACKAGE_JSON.build,
    PACKAGE_JSON.repository?.url
  );
  const tag = `v${VERSION}`;

  console.log(`Publishing Oncoreport ${tag} to ${owner}/${repo}`);
  console.log(`Release dir: ${RELEASE_DIR}`);
  console.log('');

  const octokit = new Octokit({ auth: token });

  // 1. Create the tag if it doesn't exist
  await createOrUpdateTag(octokit, owner, repo, tag, null);

  // 2. Get previous tag for changelog link
  const previousTag = await getPreviousTag(octokit, owner, repo, tag);
  if (previousTag) {
    console.log(`Previous tag: ${previousTag}`);
  } else {
    console.log('No previous tag found — this will be the first release.');
  }
  console.log('');

  // 3. Build release body
  const body = buildReleaseBody(previousTag, tag, owner, repo);

  // 4. Get or create the GitHub draft release
  const release = await getOrCreateRelease(octokit, owner, repo, tag, body);

  // 5. Collect files to upload (top-level only, skip internals and mac junk)
  const files = fs
    .readdirSync(RELEASE_DIR, { withFileTypes: true })
    .filter((e) => e.isFile())
    .map((e) => path.join(RELEASE_DIR, e.name))
    .filter((f) => !shouldSkip(path.basename(f)));

  console.log(`Found ${files.length} files to upload:`);
  files.forEach((f) => console.log(`  ${path.basename(f)}`));
  console.log('');

  // 6. Upload all files
  for (const file of files) {
    await uploadAsset(octokit, owner, repo, release.id, file);
  }

  console.log('');
  console.log(`✓ All assets uploaded.`);
  console.log(`  Release URL: ${release.html_url}`);
  console.log('');
  console.log(
    release.draft
      ? '  Release is a DRAFT. Review it on GitHub and publish when ready.'
      : '  Release is live.'
  );
}

main().catch((e) => {
  console.error('Publish failed:', e.message);
  process.exit(1);
});