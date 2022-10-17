const csv = require('csv-parser')
const fs = require('fs')

const verifyKeys = (data,requiredKeys) => {
    const keys = Object.keys(data);
    let valid = true;

    if(keys.length != requiredKeys.length) {
        valid = false;
    }

    requiredKeys.forEach( key => {
        if(!keys.includes(key)) {
            valid = false;
        }
    });

    return valid;
}


const getExperiment = async (experimentName,requiredKeys,newKeys,callback) => {
    // const results = [];
    const notValid = [];
    const resultsFiltered = {};

    let i = 0;

    await fs.createReadStream(`experiments/${experimentName}`)
    .pipe(csv())
    .on('data', (data) =>{
        i = i +1;
        const isValidData = verifyKeys(data,requiredKeys);
        const newObj = {};
        if(isValidData){
            for (let index = 0; index < Object.keys(data).length; index++) {
                newObj[newKeys[index]] = data[requiredKeys[index]];
            }

            if(resultsFiltered[newObj['[run number]']]){
                resultsFiltered[newObj['[run number]']].push(newObj);
            }else{
                resultsFiltered[newObj['[run number]']] = [];
                resultsFiltered[newObj['[run number]']].push(newObj);
            }
            // results.push(newObj);
        }else{
            notValid.push(data);
        }
    })
    .on('end', () => {
        // console.log(`processed:: ${i} lines`);
        // console.log(`invalid data:: ${notValid.length} lines`);
        // console.log(Object.keys(resultsFiltered))
        // console.log(resultsFiltered['[run number]'])
        callback(resultsFiltered,notValid);
    });

}

const getExperiments = () =>  {
    const experiments = [];
    fs.readdirSync( __dirname + '/../experiments').forEach(file => {
        experiments.push(file);
    });

    return experiments;
}

module.exports = {
    getExperiment,
    getExperiments
}