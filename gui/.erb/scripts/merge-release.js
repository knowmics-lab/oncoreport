const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const BUILD_DIR = path.resolve(__dirname, '../../release/build');
const DOCKER_DIR = path.resolve(__dirname, '../../release/build-docker');
const YAML_FILES = [
  'latest.yml',
  'latest-mac.yml',
  'latest-linux.yml',
  'beta.yml',
  'alpha.yml',
];

function mergeYaml(targetPath, sourcePath) {
  let target = {};
  let source = {};

  if (fs.existsSync(targetPath)) {
    target = yaml.load(fs.readFileSync(targetPath, 'utf8')) || {};
  }
  if (fs.existsSync(sourcePath)) {
    source = yaml.load(fs.readFileSync(sourcePath, 'utf8')) || {};
  }

  // Merge: top-level scalar fields from source win only if not in target
  // 'files' and 'path' arrays get appended/merged
  const merged = { ...source, ...target };

  // Merge 'files' array (deduplicate by 'url' field)
  const targetFiles = target.files || [];
  const sourceFiles = source.files || [];
  const allFiles = [...targetFiles];

  for (const sf of sourceFiles) {
    const exists = allFiles.some(
      (tf) => tf.url === sf.url || tf.sha512 === sf.sha512
    );
    if (!exists) allFiles.push(sf);
  }

  merged.files = allFiles;

  // Keep the version/releaseDate from whichever is present (prefer target)
  if (!merged.version && source.version) merged.version = source.version;
  if (!merged.releaseDate && source.releaseDate)
    merged.releaseDate = source.releaseDate;

  fs.writeFileSync(targetPath, yaml.dump(merged, { lineWidth: -1 }), 'utf8');
  console.log(`  Merged: ${path.basename(targetPath)}`);
}

function copyFile(src, dest) {
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.copyFileSync(src, dest);
  console.log(`  Copied: ${path.basename(dest)}`);
}

function mergeDirectories(srcDir, destDir) {
  if (!fs.existsSync(srcDir)) {
    console.error(`Source directory not found: ${srcDir}`);
    process.exit(1);
  }

  const entries = fs.readdirSync(srcDir, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(srcDir, entry.name);
    const destPath = path.join(destDir, entry.name);

    if (entry.isDirectory()) {
      fs.mkdirSync(destPath, { recursive: true });
      mergeDirectories(srcPath, destPath);
    } else if (YAML_FILES.includes(entry.name)) {
      // Merge YAML autoupdate files
      mergeYaml(destPath, srcPath);
    } else if (!fs.existsSync(destPath)) {
      // Copy only if file doesn't already exist (no overwrite)
      copyFile(srcPath, destPath);
    } else {
      console.log(`  Skipped (exists): ${path.basename(destPath)}`);
    }
  }
}

console.log('Merging release directories...');
console.log(`  Mac build:    ${BUILD_DIR}`);
console.log(`  Docker build: ${DOCKER_DIR}`);
console.log('');

mergeDirectories(DOCKER_DIR, BUILD_DIR);

console.log('');
console.log('Done. Final release artifacts in:', BUILD_DIR);