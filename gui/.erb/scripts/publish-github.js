const { Octokit } = require('@octokit/rest');
const fs = require('fs');
const path = require('path');
const { glob } = require('glob');

// --- Config ---
const RELEASE_DIR = path.resolve(__dirname, '../../release/build');
const PACKAGE_JSON = require('../../package.json');
const RELEASE_JSON = require('../../release/app/package.json');
const VERSION = RELEASE_JSON.version;

function parseRepo(buildConfig, repositoryUrl) {
    // First try build.publish (electron-builder format: {owner, repo} already parsed)
    if (buildConfig?.publish?.owner && buildConfig?.publish?.repo) {
      return {
        owner: buildConfig.publish.owner,
        repo: buildConfig.publish.repo,
      };
    }
  
    // Fall back to repository.url
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

// Files to skip uploading (builder internals, blockmap sources, etc.)
const SKIP_PATTERNS = [
  '.DS_Store',
  'builder-effective-config.yaml',
  'builder-debug.yml',
  '*.blockmap', // blockmaps are uploaded alongside their parent file
];

function shouldSkip(filename) {
  return SKIP_PATTERNS.some((pattern) => {
    if (pattern.startsWith('*')) {
      return filename.endsWith(pattern.slice(1));
    }
    return filename === pattern;
  });
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

async function getOrCreateRelease(octokit, owner, repo, tag) {
  // Try to find existing release
  try {
    const { data } = await octokit.repos.getReleaseByTag({ owner, repo, tag });
    console.log(`Found existing release: ${data.html_url}`);
    return data;
  } catch (e) {
    if (e.status !== 404) throw e;
  }

  // Create new release
  console.log(`Creating release ${tag}...`);
  const { data } = await octokit.repos.createRelease({
    owner,
    repo,
    tag_name: tag,
    name: `v${VERSION}`,
    body: `Release v${VERSION}`,
    draft: true, // draft first so you can review before publishing
    prerelease: false,
  });
  console.log(`Created draft release: ${data.html_url}`);
  return data;
}

async function uploadAsset(octokit, owner, repo, releaseId, filePath) {
  const filename = path.basename(filePath);
  const stat = fs.statSync(filePath);
  const data = fs.readFileSync(filePath);

  console.log(`  Uploading ${filename} (${(stat.size / 1024 / 1024).toFixed(1)} MB)...`);

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
    console.error('Error: GH_TOKEN or GITHUB_TOKEN environment variable is required');
    process.exit(1);
  }

  const { owner, repo } = parseRepo(PACKAGE_JSON.build, PACKAGE_JSON.repository?.url);
  const tag = `v${VERSION}`;

  console.log(`Publishing Oncoreport ${tag} to ${owner}/${repo}`);
  console.log(`Release dir: ${RELEASE_DIR}`);
  console.log('');

  const octokit = new Octokit({ auth: token });

  // Get or create the GitHub release
  const release = await getOrCreateRelease(octokit, owner, repo, tag);

  // Collect all files to upload (top-level only, not subdirectories)
  const files = fs
    .readdirSync(RELEASE_DIR, { withFileTypes: true })
    .filter((e) => e.isFile())
    .map((e) => path.join(RELEASE_DIR, e.name))
    .filter((f) => !shouldSkip(path.basename(f)));

  console.log(`Found ${files.length} files to upload:`);
  files.forEach((f) =>
    console.log(`  ${path.basename(f)}`)
  );
  console.log('');

  // Upload all files
  for (const file of files) {
    await uploadAsset(octokit, owner, repo, release.id, file);
  }

  console.log('');
  console.log(`✓ All assets uploaded.`);
  console.log(`  Release URL: ${release.html_url}`);
  console.log('');
  console.log(
    release.draft
      ? '  Release is a DRAFT. Go to GitHub to review and publish it.'
      : '  Release is live.'
  );
}

main().catch((e) => {
  console.error('Publish failed:', e.message);
  process.exit(1);
});