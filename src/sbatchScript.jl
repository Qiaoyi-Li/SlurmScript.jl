function sbatchScript(args...;kwargs...) 

     filename = generateScript(args...;kwargs...)
     run(`sbatch $(filename)`)
     return nothing
end