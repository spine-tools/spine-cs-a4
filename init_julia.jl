using Pkg

# ACtivate current environment
Pkg.activate(".")

# Download all required packages listed in Manifest.toml
Pkg.instantiate()

# Set Python executable to current and re-build PyCall
ENV["PYTHON"] = Sys.which("python")
Pkg.build("PyCall")
