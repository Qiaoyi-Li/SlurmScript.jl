function sbatchScript(args...; kwargs...)

	filename = generateScript(args...; kwargs...)
	requeue::Bool = get(kwargs, :requeue, false)

	if !requeue
          run(`sbatch --no-requeue $(filename)`)
	else
		run(`sbatch $(filename)`)
	end
	return nothing
end
