using Pkg

# Activate the project’s Julia environment
Pkg.activate(".julia")

# Download all required packages listed in Manifest.toml
Pkg.instantiate()

# Set Python executable and re-build PyCall
ENV["PYTHON"] = Sys.which("python")
Pkg.build("PyCall")
using PyCall
println("Using Python executable at '$(PyCall.python)'")
