function generateScript(
     jlfile::String,
     filename::String,
     partition::String,
     mem::Int64,
     nthreads_slurm::Int64,
     maxtime::String;
     kwargs...)

     # check args
     a = _check_filename(filename)
     maxtime = _check_time(maxtime)

     # default
     jobname = get(kwargs, :jobname, filename[a+1:end-3])
     nodes::Int64 = get(kwargs, :nodes, 1)
     tpn::Int64 = get(kwargs, :tpn, 1)
     exclude::Union{String, Nothing} = get(kwargs, :exclude, nothing)
     logname::String = get(kwargs, :logname, filename[1:end-3] * ".log") 
     nthreads_julia::Int64 = get(kwargs, :nthreads_julia, nthreads_slurm)
     nthreads_mkl::Int64 = get(kwargs, :nthreads_mkl, 1)
     heap_size_hint::Int64 = get(kwargs, :heap_size_hint, round(0.8*mem))
     project::String = get(kwargs, :project, pwd())
     depot = get(kwargs, :depot, nothing)
     offline::Bool= get(kwargs, :offline, false)

     exclusive::Bool = get(kwargs, :exclusive, false)

     file = open(filename, "w+")

     # slurm parameters
     println(file, "#!/bin/bash")
     println(file, "#SBATCH --job-name=$(jobname)")
     println(file, "#SBATCH --partition=$(partition)")
     println(file, "#SBATCH --mem=$(mem)gb")
     println(file, "#SBATCH --nodes=$(nodes)")
     println(file, "#SBATCH --ntasks-per-node=$(tpn)")
     println(file, "#SBATCH --cpus-per-task=$(nthreads_slurm)")
     println(file, "#SBATCH --time=$(maxtime)")
     !isnothing(exclude) && println(file, "SBATCH --exclude=$(exclude)")
     exclusive && println(file, "#SBATCH --exclusive")
     println(file, "#SBATCH --output=$(logname)")

     # julia script
     print(file, "MKL_NUM_THREADS=$(nthreads_mkl) ") # set MKL nthreads
     !isnothing(depot) && print(file, "JULIA_DEPOT_PATH=$(depot) ")
     offline && print(file, "JULIA_PKG_OFFLINE=true ")
     print(file, "julia ")
     print(file, "-t$(nthreads_julia) ")
     print(file, "--heap-size-hint=$(heap_size_hint)G ")
     print(file, "--project=$(project) ")
     println(file, jlfile)

     close(file)

     return filename
end

function _check_filename(filename::String)

     @assert filename[end-2:end] == ".sh"
     a = findlast('/', filename)
     if !isnothing(a) 
          mkpath(filename[1:a])
          return a
     else
          return 0
     end
end

function _check_time(maxtime::String)
     rx = r"^(?<dd>\d\d?)-(?<hh>\d\d?):(?<mm>\d\d?):(?<ss>\d\d?)$"
     m = match(rx, maxtime)
     @assert !isnothing(m)

     str = lpad.(m, 2, "0")
     return "$(str[1])-$(str[2]):$(str[3]):$(str[4])"
end