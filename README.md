Spine Case Study A4 Week Long Demo
==================================

Requires Python 3.7, virtualenv and Julia 1.2.

# Instructions

## Python environment

First create a Python virtual environment and activate it.

    > virtualenv venv
    > venv\Scripts\activate
    
On Linux, use `source venv/bin/activate`.
    
Install Python dependencies.

    (venv) > pip install -r requirements.txt
    
    
## Julia environment
    
Instantiate Julia environment with

    (venv) > julia init_julia.jl


## Launch Spine Toolbox

You should now be able to launch Spine Toolbox using

    (venv) > spinetoolbox
    
In the Toolbox settings, you need to set the active Julia project to the 
current project directory.
