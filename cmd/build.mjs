// Dependencies
import { renderFile } from 'ejs';
import { sha256 } from 'hash-wasm';
import versions from './versions.mjs';
import { writeFile, symlink } from 'fs/promises';
import logSymbols from 'log-symbols';
import MFH from 'make-fetch-happen';
import mri from 'mri';
import path from 'path';

const argv = process.argv.slice(2);
const { _: customVersions } = mri(argv);

const fetch = MFH.defaults({
  cacheManager: '.cache',
});

const __dirname = path.resolve(path.dirname(''));

// via https://codeburst.io/javascript-async-await-with-foreach-b6ba62bbf404
async function asyncForEach(array, callback) {
  for (let index = 0; index < array.length; index++) {
    await callback(array[index], index, array);
  }
}

async function getHash(blob) {
  const data = new Uint8Array(blob);
  const checksum = await sha256(data);

  return checksum;
}

async function template(outFile, data) {
  data.classPrefix = outFile.startsWith('Aliases/') ? 'Nsis' : 'Makensis';

  renderFile(
    path.join(__dirname, `cmd/templates/nsis@${data.versionMajor}.ejs`),
    data,
    async (err, contents) => {
      if (err) {
        console.error(logSymbols.error, err);
        return;
      }

      await writeFile(outFile, contents);

      console.log(logSymbols.success, `Saved: ${outFile}`);
    }
  );
}

const createManifest = async (version) => {
  let data = {};

  data.version = version;
  data.versionMajor = version[0];
  data.versionNoDot = version.replace(/\./g, '');
  data.directory =
    /\d(a|b|rc)\d*$/.test(data.version) === true
      ? `NSIS%20${data.versionMajor}%20Pre-release`
      : `NSIS%20${data.versionMajor}`;

  const bzUrl = `https://downloads.sourceforge.net/project/nsis/${data.directory}/${data.version}/nsis-${data.version}-src.tar.bz2`;
  const zipUrl = `https://downloads.sourceforge.net/project/nsis/${data.directory}/${data.version}/nsis-${data.version}.zip`;
  const strlenZipUrl = `https://downloads.sourceforge.net/project/nsis/${data.directory}/${data.version}/nsis-${data.version}-strlen_8192.zip`;

  try {
    const responseBzip = await fetch(bzUrl);
    data.hashBzip2 = await getHash(await responseBzip.arrayBuffer());

    const responseZip = await fetch(zipUrl);
    data.hashZip = await getHash(await responseZip.arrayBuffer());

    const responseStrlenZip = await fetch(strlenZipUrl);
    data.hashStrlenZip = await getHash(await responseStrlenZip.arrayBuffer());

    await template(`Formula/makensis@${data.version}.rb`, data);
  } catch (error) {
    if (error.statusMessage) {
      if (error.statusMessage === 'Too Many Requests') {
        return console.warn(
          logSymbols.warning,
          `${error.statusMessage}: nsis-${version}.zip`
        );
      }
      return console.error(
        logSymbols.error,
        `${error.statusMessage}: nsis-${version}.zip`
      );
    } else if (error.code === 'ENOENT') {
      return console.log('Skipping Test: Manifest Not Found');
    }

    console.error(logSymbols.error, error);
  }

  try {
    await symlink(
      `../Formula/makensis@${data.version}.rb`,
      `Aliases/nsis@${data.version}.rb`
    );
    console.log(logSymbols.success, `Saved: Aliases/nsis@${data.version}.rb`);
  } catch (error) {
    console.error(
      logSymbols.warning,
      `Skipping: Aliases/nsis@${data.version}.rb`
    );
  }
};

const allVersions =
  Array.isArray(customVersions) && customVersions.length
    ? customVersions
    : versions;

console.info(
  logSymbols.info,
  `Creating ${allVersions.length} ${
    allVersions.length === 1 ? 'manifest' : 'manifests'
  }`
);

// All versions
asyncForEach(allVersions, async (key) => {
  const value = versions[key];
  await createManifest(key, value);
});
