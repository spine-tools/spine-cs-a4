Spine Case Study A4 Week Long Demo
==================================

Spine Toolbox project for the workflow of case study A4, aiming to demonstrate 
some key functionality required for replicating RealValue project results.

# Instructions

## Python environment

Python 3.7 and `virtualenv` package is required.

First create a Python virtual environment and activate it.

    > virtualenv .venv
    > .venv\Scripts\activate
    
On Linux, use `source venv/bin/activate`.
    
Install Python dependencies.

    (.venv) > pip install -r requirements.txt
    
    
## Julia environment

Julia 1.2 is required.
    
Instantiate Julia environment with

    (.venv) > julia init_julia.jl


## Spine Toolbox

You should now be able to launch Spine Toolbox using

    (.venv) > spinetoolbox
    
In the Toolbox settings, you need to set the active Julia project to the 
`.julia` directory.
