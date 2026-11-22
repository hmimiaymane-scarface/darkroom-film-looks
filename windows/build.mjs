// Builds the Windows installer: node build.mjs   (or: node build.mjs --prepare to only copy files)
// Works from macOS or Linux without Wine: the .exe icon and version info are set with resedit.
import { execSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(here, '..');
const run = (cmd) => execSync(cmd, { cwd: here, stdio: 'inherit' });
const pkg = JSON.parse(fs.readFileSync(path.join(here, 'package.json'), 'utf8'));

// 1. App files and icons
fs.mkdirSync(path.join(here, 'app'), { recursive: true });
fs.copyFileSync(path.join(root, 'darkroom.html'), path.join(here, 'app', 'darkroom.html'));
fs.mkdirSync(path.join(here, 'build-res'), { recursive: true });
const png = path.join(here, 'icon.png');
if (!fs.existsSync(png)) run(`swift ../mac/icon.swift "${png}"`);
const ico = path.join(here, 'build-res', 'icon.ico');
if (!fs.existsSync(ico)) {
  // An .ico file can hold PNG images directly (Windows Vista and later).
  const sizes = [16, 24, 32, 48, 64, 128, 256], imgs = [];
  for (const s of sizes) {
    const out = path.join(here, 'build-res', `i${s}.png`);
    execSync(`sips -z ${s} ${s} "${png}" --out "${out}"`, { stdio: 'ignore' });
    imgs.push(fs.readFileSync(out)); fs.rmSync(out);
  }
  const head = Buffer.alloc(6 + 16 * sizes.length);
  head.writeUInt16LE(0, 0); head.writeUInt16LE(1, 2); head.writeUInt16LE(sizes.length, 4);
  let off = head.length;
  sizes.forEach((s, i) => {
    const e = 6 + i * 16;
    head.writeUInt8(s === 256 ? 0 : s, e); head.writeUInt8(s === 256 ? 0 : s, e + 1);
    head.writeUInt16LE(1, e + 4); head.writeUInt16LE(32, e + 6);
    head.writeUInt32LE(imgs[i].length, e + 8); head.writeUInt32LE(off, e + 12); off += imgs[i].length;
  });
  fs.writeFileSync(ico, Buffer.concat([head, ...imgs]));
}
if (process.argv.includes('--prepare')) process.exit(0);

// 2. Unpacked Windows app
const common = `--config.appId=io.github.darkroom.app --config.productName=Darkroom --config.directories.output=dist ` +
  `--config.files=main.js --config.files=preload.js --config.files=icon.png --config.files="app/**"`;
fs.rmSync(path.join(here, 'dist'), { recursive: true, force: true });
run(`npx electron-builder --win dir --x64 ${common} --config.win.signAndEditExecutable=false`);

// 3. Icon + version info on Darkroom.exe
const ResEdit = await import('resedit');
const exePath = path.join(here, 'dist', 'win-unpacked', 'Darkroom.exe');
const exe = ResEdit.NtExecutable.from(fs.readFileSync(exePath), { ignoreCert: true });
const res = ResEdit.NtExecutableResource.from(exe);
const icon = ResEdit.Data.IconFile.from(fs.readFileSync(ico));
const groups = ResEdit.Resource.IconGroupEntry.fromEntries(res.entries);
ResEdit.Resource.IconGroupEntry.replaceIconsForResource(res.entries, groups[0].id, groups[0].lang, icon.icons.map((i) => i.data));
const [vi] = ResEdit.Resource.VersionInfo.fromEntries(res.entries);
const [major, minor, patch] = pkg.version.split('.').map(Number);
const lang = { lang: 1033, codepage: 1200 };
vi.setStringValues(lang, {
  ProductName: 'Darkroom', FileDescription: 'Darkroom', CompanyName: pkg.author, InternalName: 'Darkroom',
  OriginalFilename: 'Darkroom.exe', LegalCopyright: `MIT License, ${pkg.author}`, ProductVersion: pkg.version, FileVersion: pkg.version,
});
vi.removeStringValue(lang, 'Comments');
vi.setFileVersion(major, minor, patch, 0, 1033); vi.setProductVersion(major, minor, patch, 0, 1033);
vi.outputToResourceEntries(res.entries);
res.outputResource(exe);
fs.writeFileSync(exePath, Buffer.from(exe.generate()));
console.log('› Set Darkroom.exe icon and version info');

// 4. Installer (one click, per user, no admin rights needed)
run(`npx electron-builder --win nsis --x64 --prepackaged dist/win-unpacked ${common} ` +
  `--config.win.signAndEditExecutable=false --config.win.icon=build-res/icon.ico ` +
  `--config.nsis.oneClick=true --config.nsis.perMachine=false --config.nsis.runAfterFinish=true ` +
  `--config.nsis.createDesktopShortcut=always --config.nsis.createStartMenuShortcut=true ` +
  `--config.nsis.shortcutName=Darkroom --config.nsis.installerIcon=build-res/icon.ico ` +
  `--config.nsis.uninstallerIcon=build-res/icon.ico '--config.nsis.artifactName=Darkroom-Setup-\${version}.exe'`);
console.log('✓ Built', fs.readdirSync(path.join(here, 'dist')).filter((f) => f.endsWith('.exe')).join(', '));
