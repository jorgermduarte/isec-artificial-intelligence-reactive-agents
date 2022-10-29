const express = require('express')
const express_layouts = require('express-ejs-layouts')
const render = require('./libs/render.lib')
const experimentLib = require('./libs/experiments.lib')

const server = express()

server.set('trust proxy', 1)
server.use(express.json())
server.set('view engine', 'ejs')

server.use(express_layouts)

server.set('views', __dirname + '/views')
server.use('/public', express.static(process.cwd() + '/wwwroot'))

server.get('/', (req, res) => {
    const experiments =  experimentLib.getExperiments()
    new render(req,res)
    .SetData({ experiments: [...experiments]})
    .Render('experiments')
});

server.get('/experiments/basic/:experiment', async (req, res) => {

    const requiredKeys = ['BehaviorSpace results (NetLogo 6.3.0)','_1','_2','_3','_4','_5','_6','_7','_8','_9'];
    const newKeys = ["[run number]","n-shelter","yellow-food-percentage","n-basic-agent","n-expert-agent","green-food-percentage","trap-percentage","[step]","count basic-agent","count expert-agent"];

    const experimentName = req.params.experiment;
    let default_experiment = null;

    if(experimentName != 'base-model-default-table.csv'){
        default_experiment = await experimentLib.getExperiment("base-model-default-table.csv",requiredKeys,newKeys);
    }

    const data = await experimentLib.getExperiment(experimentName,requiredKeys,newKeys);
        new render(req,res)
        .SetData({
            experiment: JSON.stringify(data),
            experiment_name: experimentName,
            default_experiment: default_experiment != null ? JSON.stringify(default_experiment): null,
            model_type: "basic"
        })
        .Render('preview')
});

server.get('/experiments/upgraded/:experiment', async (req, res) => {

    const requiredKeys = [
        'BehaviorSpace results (NetLogo 6.3.0)',
        '_1',
        '_2',
        '_3',
        '_4',
        '_5',
        '_6',
        '_7',
        '_8',
        '_9',
        '_10',
        '_11'
    ];
    const newKeys = [
        "[run number]",
        "yellow-food-percentage",
        "n-shelter",
        "expert-kill-basic-min-energy",
        "n-basic-agent",
        "n-expert-agent",
        "green-food-percentage",
        "basic-agent-camouflage-percentage",
        "trap-percentage",
        "[step]",
        "count basic-agent",
        "count expert-agent"
    ]
    const experimentName = req.params.experiment;
    let default_experiment = null;

    if(experimentName != 'upgraded-model-default-table.csv'){
        default_experiment = await experimentLib.getExperiment("upgraded-model-default-table.csv",requiredKeys,newKeys);
    }

    const data = await experimentLib.getExperiment(experimentName,requiredKeys,newKeys);
        new render(req,res)
        .SetData({
            experiment: JSON.stringify(data),
            experiment_name: experimentName,
            default_experiment: default_experiment != null ? JSON.stringify(default_experiment): null,
            model_type: "upgraded"
        })
        .Render('preview')
});
server.listen(3000, () => console.log("server started successfully at port 3000"));


