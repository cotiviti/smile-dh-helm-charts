
Object.defineProperty(exports, "__esModule", { value: true });

const fs_1 = require("fs");
const js_yaml_1 = require("js-yaml");
const path_1 = require("path");
const argon = require('argon2');
const crypto = require('crypto');
const StreamObject_1 = require("stream-json/streamers/StreamObject");
const Stream = require("stream");

const pLimit = require('p-limit');
// Set the maximum number of concurrent workers to 4
const limit = pLimit(4);

const logger_1 = require("directus/logger");

const services_1 = require("directus/services/index");
const get_schema_1 = require("directus/utils/get-schema");

const apply_snapshot_1 = require("directus/utils/apply-snapshot");
const get_snapshot_1 = require("directus/utils/get-snapshot");
const get_snapshot_diff_1 = require("directus/utils/get-snapshot-diff");

exports.down = exports.up = void 0;
async function up(knex) {
    const schemaSnapshotFileName = path_1.resolve(process.cwd(), "pmp-schema.yaml");
    const database = knex;
    let snapshot;
    try {
        const fileContents = await fs_1.promises.readFile(schemaSnapshotFileName, 'utf8');
        snapshot = (await (0, js_yaml_1.load)(fileContents));
        const currentSnapshot = await (0, get_snapshot_1.getSnapshot)({ database });
        const snapshotDiff = (0, get_snapshot_diff_1.getSnapshotDiff)(currentSnapshot, snapshot);
        if (snapshotDiff.collections.length === 0 &&
            snapshotDiff.fields.length === 0 &&
            snapshotDiff.relations.length === 0) {
            logger_1.default.info('Apply Schema Snapshot: No changes to apply.');
        } else {
            await (0, apply_snapshot_1.applySnapshot)(snapshot, { current: currentSnapshot, diff: snapshotDiff, database });
            logger_1.default.info(`Apply Schema Snapshot: Success`);
        }
    }
    catch (err) {
        logger_1.default.error(err);
    }
    const collections = await getCollections();
    var roleId = crypto.randomUUID();
    var userId = crypto.randomUUID();
    await knex('directus_roles')
        .select('id', 'name')
        .where('name', 'App Access')
        .then(result => {
            if (result.length === 0) {
                return knex('directus_roles').insert([
                    { id: roleId, name: 'App Access', icon: 'supervised_user_circle', admin_access: true }
                ])
                    .then(result => {
                        if (result.rowCount > 0) {
                            logger_1.default.info(`Create App Access Role with id ${roleId}: Success`);
                        } else {
                            logger_1.default.info(`Create App Access Role with id ${roleId}: Skipped (Why???)`);
                        }
                    });
            }
            logger_1.default.info(`Create App Access Role: Skipped (exists)`);
            roleId = result[0].id;
            logger_1.default.info(`   * Using existing roleId: ${roleId}`);
            return;
        }).catch(err => { console.log(err) });

    const appUserEmail = process.env.PMP_APP_USER_EMAIL;
    const appUserPassword = process.env.PMP_APP_USER_PASSWORD;
    await knex('directus_users').insert([
        { id: userId, email: appUserEmail, password: await argon.hash(appUserPassword), role: roleId }])
        .then(result => {
            if (result.rowCount > 0) {
                logger_1.default.info(`Create App Access User (${appUserEmail}): Success`);
            } else {
                logger_1.default.info(`Create App Access User (${appUserEmail}): Skipped (Why???)`);
            }
        })
        .catch((err) => {
            //console.log(err);
            logger_1.default.info(`Create App Access User (${appUserEmail}): Skipped (exists)`);
        });
    const collectionPermissions = collections.map(collection =>
        ({ collection: collection, action: 'read', permissions: '{}', validation: '{}', fields: '*' }));
    await knex('directus_permissions').insert(collectionPermissions)
        .then(result => {
            result && result.rowCount > 0 ? logger_1.default.info(`Update Collection Permissions: Success`) : null
        });
    await importAllCollections();
    logger_1.default.info(`Import initial items: Success`);
    const signupLink = process.env.PMP_IDP_SIGNUP_LINK;
    await knex('IDPSignup').insert({ signup_link: signupLink })
        .then(result => {
            result && result.rowCount > 0 ? logger_1.default.info(`Update Signup Link (${signupLink}): Success`) : null
        });
}
exports.up = up;
async function down(knex) {
    let result;
    const appUserEmail = process.env.PMP_APP_USER_EMAIL;
    const roleId = await knex('directus_users').where('email', appUserEmail).select('role').then(
        result => {
            return result && result.length > 0 ? result[0]['role'] : null;
        }).catch(err => { console.log(err) });
    if (roleId) {
        logger_1.default.info(`Found Role ID (${roleId}) for user (${appUserEmail})`);
        await knex('directus_users').where('email', appUserEmail).del().catch(err => { console.log(err) })
            .then(result => {
                if (result > 0) {
                    logger_1.default.info(`Remove App Access User (${appUserEmail}): Success`)
                } else {
                    logger_1.default.info(`Remove App Access User (${appUserEmail}): Nope...`)
                }
            });
        await knex('directus_roles').where('id', roleId).del().catch(err => { console.log(err) })
            .then(result => {
                if (result > 0) {
                    logger_1.default.info(`Remove App Access Role (${roleId}): Success`)
                } else {
                    logger_1.default.info(`Remove App Access Role (${roleId}): Nope...`)
                }
            });
    } else {
        logger_1.default.info(`User (${appUserEmail}) not found. Nothing to delete.`);
    }

    const collections = await getCollections();
    await knex('directus_permissions').whereIn('collection', collections).del()
        .then(result => {
            if (result > 0) {
                logger_1.default.info(`Revert Collection Permissions: Success`)
            } else {
                logger_1.default.info(`Revert Collection Permissions: Nope...`)
            }
        });
    logger_1.default.info(`Not removing schema snapshot as it's unsupported.`);
}
exports.down = down;

async function getCollections() {
    const dbSchema = await (0, get_schema_1.getSchema)();
    const allCollections = Object.keys(dbSchema.collections);
    const pmpCollections = allCollections.filter(item => {
        return !item.startsWith("directus_");
    });
    const sysReadCollections = [
        'directus_collections',
        'directus_fields',
        'directus_files',
        'directus_folders',
    ];
    return pmpCollections.concat(sysReadCollections);
}

async function importItems(collection, schema, data) {
    let numItems = 0;
    try {
        const importer = new services_1.ImportService({ schema });
        //logger_1.default.info(`Importing data for collection: ${collection}`);
        const mystream = Stream.Readable({
            objectMode: false,
            read() { }
        });
        //logger_1.default.info(`Created stream`);
        let firstElement = true;
        mystream.push("[");
        data.forEach(item => {
            if (firstElement) {
                firstElement = false;
            } else {
                mystream.push(",");
            }
            numItems++;
            mystream.push(JSON.stringify(item));
        });
        mystream.push("]")
        mystream.push(null)
        // logger_1.default.info(`Pushed all data to stream`);
        // logger_1.default.info(`Calling importer.importJSON with collection: ${collection} and stream: ${mystream}`);
        await importer.importJSON(collection, mystream);
        // logger_1.default.info(`ImportItems imported data for collection: ${collection}`);
    } catch (err) {
        logger_1.default.error(`Failed to import data for collection: ${collection}`);
        logger_1.default.error(err);
    }
    return numItems;
}

async function importAllCollections() {
    const itemsImportFileName = path_1.resolve(process.cwd(), "pmp-items.json");
    const schema = await (0, get_schema_1.getSchema)();
    const pipeline = fs_1.createReadStream(itemsImportFileName).pipe(StreamObject_1.withParser());

    const schemaCollections = Object.keys(schema.collections);
    let dataHandlersCount = 0;
    const dataHandlersCompletePromise = new Promise(resolve => {

        pipeline.on('data', async (data) => {

            if (schemaCollections.includes(data.key) && data.value.length > 0) {
                //logger_1.default.info(`Importing data for collection: ${data.key}`);
                try {
                    let numItems;
                    dataHandlersCount++;
                    await limit(async () => {
                        numItems = await importItems(data.key, schema, data.value);
                    })
                    logger_1.default.info(`Imported ${numItems} items for collection: ${data.key}`);
                } catch (err) {
                    logger_1.default.error(`Failed to import data for collection: ${data.key}`);
                    logger_1.default.error(err);
                } finally {
                    dataHandlersCount--;
                    if (dataHandlersCount === 0) {
                        // logger_1.default.info(`All data handlers complete`);
                        resolve();
                    }
                }
            } else {
                logger_1.default.info(`Collection does not exist in DB or import has no data: ${data.key}`);
            }
        });
    });
    pipeline.on('end', async () => {
        // If there are no data handlers, exit the program
        if (dataHandlersCount > 0) {
            await dataHandlersCompletePromise;
        }
        logger_1.default.info(`Reached end of stream. Exiting!`);
        //process.exit();
    });

    pipeline.on('error', (err) => {
        logger_1.default.error('An error occurred while reading the file:', err);
        //process.exit(1);
    });
    await dataHandlersCompletePromise;
}
