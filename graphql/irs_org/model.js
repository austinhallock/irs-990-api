import _ from 'lodash';
import { Base, cknex, elasticsearch, Format } from 'backend-shared';
import config from '../../config';

class IrsOrgModel extends Base {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.match(/return (?:_assertThisInitialized\()*(\w+)\)*;/)[1];
      eval(`${thisName} = this;`);
    }
    this.getByEin = this.getByEin.bind(this);
    super(...args);
  }

  getScyllaTables() {
    return [
      {
        name: 'irs_orgs_by_ein',
        keyspace: 'irs_990_api',
        fields: {
          ein: 'text',
          name: 'text',
          city: 'text',
          state: 'text', // 2 letter code
          nteecc: 'text', // https://nccs.urban.org/project/national-taxonomy-exempt-entities-ntee-codes

          website: 'text',
          mission: 'text',
          exemptStatus: 'text',

          assets: 'bigint',
          netAssets: 'bigint',
          liabilities: 'bigint',
          employeeCount: 'int',
          volunteerCount: 'int',

          lastYearStats: 'json'
        },
        primaryKey: {
          partitionKey: ['ein']
        }
      }
    ];
  }

  getElasticSearchIndices() {
    return [
      {
        name: 'irs_orgs',
        mappings: {
          ein: {type: 'text'},
          name: {type: 'search_as_you_type'},
          city: {type: 'text'},
          state: {type: 'text'},
          nteecc: {type: 'text'},

          website: {type: 'text'},
          mission: {type: 'text'},
          exemptStatus: {type: 'text'},

          assets: {type: 'long'},
          netAssets: {type: 'long'},
          liabilities: {type: 'long'},
          employeeCount: {type: 'integer'},
          volunteerCount: {type: 'integer'},

          lastYearStats: {
            properties: {
              year: {type: 'integer'},
              revenue: {type: 'long'},
              expenses: {type: 'long'},
              revenue: {type: 'long'},
              topSalary: {
                properties: {
                  name: {type: 'text'},
                  title: {type: 'text'},
                  compensation: {type: 'int'}
                }
              }
            }
          },

          websiteText: {type: 'text'}
        } // TODO: move to diff table?
      }
    ];
  }

  getByEin(ein) {
    return cknex().select('*')
    .from('irs_orgs_by_ein')
    .where('ein', '=', ein)
    .run({isSingle: true})
    .then(this.defaultOutput);
  }
}

export default new IrsOrgModel();
