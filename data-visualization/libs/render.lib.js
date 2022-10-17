class Render{

    #request;
    #response;
    
    #object_data = {
        auth : {},
        data : null
    }

    constructor(req,res){
        this.#request = req;
        this.#response =  res;
        this.#SetAuthenticationDetails()
    }

    SetData = d => {
        this.#object_data.data = d
        return this
    }
    GetData = () => this.#object_data.data
    GetAuth = () => this.#object_data.auth

    #SetAuthenticationDetails(){
        let user_session = this.#request.session
        if(user_session?.user)
            this.#object_data.auth = this.#request.session.user
        else
            this.#object_data.auth = {}
    }

    Render(view,layout = "index"){
        this.#response.render(`pages/${view.toLowerCase()}`, { layout : `layouts/${layout.toLowerCase()}`, data : this.#object_data.data, auth : this.#object_data.auth })
    }
    
}

module.exports = Render