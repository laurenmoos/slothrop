module Slothrop

using Distributed
using Dates
using TOML
using StatsBase
using Statistics


#const IN_SLURM = "SLURM_JOBID" in keys(ENV)
#IN_SLURM && using ClusterManagers

# The implicit PWD for the master node is the parent dir
# of this file.
include("Evo.jl")
# Annoyingly, the implicit PWD for workers is up a step
@everywhere include("src/Evo.jl")

@everywhere OBSERVER = nothing

function dispatch(config)
    started = now()
    @info "In Slothrop::dispatch. Elapsed: $(now() - started)"

    if config isa String
        config = TOML.parsefile(config)
    end
    binary_path = config["binary"]
    @everywhere $Evo.Hatchery.load($binary_path)
    @info "Loaded Evo module. Elapsed: $(now() - started)"

    geo = Evo.geography(config)

    # Initialize the observers
    observer = Evo.Observer(config)
    @everywhere global OBSERVER = $observer
    
    # let's do a few test tournaments
    n = config["iterations"]
    @info "Running $n tournaments..."
    t_start = now()
    @time @sync for _ in 1:n
        Evo.tournament!(geo)
    end
    @info "Finished $n tournaments in $(now() - t_start)."
    #population = [Evo.rfetch(g) for g in geo.deme] |> vec
    #sort!(population,
    #      rev=true,
    #      by=(g -> ismissing(g.scalar_fitness) ? 0.0 : g.scalar_fitness))
    #fits = [g.scalar_fitness for g in population] |> skipmissing
    #@info "Mean fitness: $(mean(fits))"
    #@info "Standard deviation: $(std(fits))"
    #@info "Maximum fitness: $(maximum(fits))"
    #@info "Champion:\n$(first(population))"
    @info "Total time elapsed: $(now() - started)"

    geo
end




end # module
