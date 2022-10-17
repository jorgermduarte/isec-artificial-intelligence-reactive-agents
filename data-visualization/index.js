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

server.get('/experiments/:experiment', (req, res) => {

    const requiredKeys = ['BehaviorSpace results (NetLogo 6.3.0)','_1','_2','_3','_4','_5','_6','_7','_8','_9'];
    const newKeys = ["[run number]","yellow-food-percentage","n-shelter","n-basic-agent","green-food-percentage","n-expert-agent","trap-percentage","[step]","count basic-agent","count expert-agent"];

    const experimentName = req.params.experiment;

    const experiment = experimentLib.getExperiment(experimentName,requiredKeys,newKeys,(data,notValid) => {
        new render(req,res)
        .SetData({
            experiment: JSON.stringify(data)
        })
        .Render('preview')
    });
});

server.listen(3000, () => console.log("server started successfully at port 3000"));


