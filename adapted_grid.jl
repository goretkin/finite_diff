
import Random: MersenneTwister
"""
    adapted_grid(f, minmax::Tuple{Number, Number}; max_recursions = 7)

Computes a grid `x` on the interval [minmax[1], minmax[2]] so that
`plot(f, x)` gives a smooth "nice" plot.
The method used is to create an initial uniform grid (21 points) and refine intervals
where the second derivative is approximated to be large. When an interval
becomes "straight enough" it is no longer divided.

The parameter `max_recusions` computes how many times each interval is allowed to
be refined.

The parameter `wiggle`: Wiggle interior points a bit to prevent aliasing and other degenerate cases
The parameter `max_curvature`: When an interval has curvature smaller than this, stop refining it.
"""
function gg_adapted_grid(f, minmax::Tuple{Real, Real}; max_recursions = 7, wiggle = true, max_curvature = 0.05)
    if minmax[1] >= minmax[2]
        throw(ArgumentError("interval must be given as (min, max)"))
    end

    # Initial number of points
    n_points = 21
    n_intervals = n_points ÷ 2
    @assert isodd(n_points)

    xs = collect(range(minmax[1]; stop=minmax[2], length=n_points))

    if wiggle
        rng = MersenneTwister(1337)
        rand_factor = 0.05
        for i in 2:length(xs)-1
            xs[i] += rand_factor * 2 * (rand(rng) - 0.5) * (xs[i+1] - xs[i-1])
        end
    end
    n_tot_refinements = zeros(Int, n_intervals)

    fs = [f(x) for x in xs]
    while true
        curvatures = zeros(n_intervals)
        active = falses(n_intervals)
        isfinite_f = isfinite.(fs)
        min_f, max_f = any(isfinite_f) ? extrema(fs[isfinite_f]) : (0.0, 0.0)
        f_range = max_f - min_f
        # Guard against division by zero later
        if f_range == 0 || !isfinite(f_range)
            f_range = one(f_range)
        end
        # Skip first and last interval
        for interval in 1:n_intervals
            p = 2 * interval
            if n_tot_refinements[interval] >= max_recursions
                # Skip intervals that have been refined too much
                active[interval] = false
            elseif !all(isfinite.(fs[[p-1,p,p+1]]))
                active[interval] = true
            else
                tot_w = 0.0
                # Do a small convolution
                for (q,w) in ((-1, 0.25), (0, 0.5), (1, 0.25))
                    interval == 1 && q == -1 && continue
                    interval == n_intervals && q == 1 && continue
                    tot_w += w
                    i = p + q
                    # Estimate integral of second derivative over interval, use that as a refinement indicator
                    # https://mathformeremortals.wordpress.com/2013/01/12/a-numerical-second-derivative-from-three-points/
                    curvatures[interval] += abs(2 * ((fs[i+1] - fs[i]) / ((xs[i+1]-xs[i]) * (xs[i+1]-xs[i-1]))
                                                    -(fs[i] - fs[i-1]) / ((xs[i]-xs[i-1]) * (xs[i+1]-xs[i-1])))
                                                    * (xs[i+1] - xs[i-1])^2) / f_range * w
                end
                curvatures[interval] /= tot_w
                # Only consider intervals with a high enough curvature
                active[interval] = curvatures[interval] > max_curvature
            end
        end

        if all(x -> x >= max_recursions, n_tot_refinements[active])
            break
        end

        n_target_refinements = n_intervals ÷ 2
        interval_candidates = collect(1:n_intervals)[active]
        n_refinements = min(n_target_refinements, length(interval_candidates))
        perm = sortperm(curvatures[active])
        intervals_to_refine = sort(interval_candidates[perm[length(perm) - n_refinements + 1:end]])
        n_intervals_to_refine = length(intervals_to_refine)
        n_new_points = 2*length(intervals_to_refine)

        # Do division of the intervals
        new_xs = zeros(eltype(xs), n_points + n_new_points)
        new_fs = zeros(eltype(fs), n_points + n_new_points)
        new_tot_refinements = zeros(Int, n_intervals + n_intervals_to_refine)
        k = 0
        kk = 0
        for i in 1:n_points
            if iseven(i) # This is a point in an interval
                interval = i ÷ 2
                if interval in intervals_to_refine
                    kk += 1
                    new_tot_refinements[interval - 1 + kk] = n_tot_refinements[interval] + 1
                    new_tot_refinements[interval + kk] = n_tot_refinements[interval] + 1

                    k += 1
                    new_xs[i - 1 + k] = (xs[i] + xs[i-1]) / 2
                    new_fs[i - 1 + k] = f(new_xs[i-1 + k])

                    new_xs[i + k] = xs[i]
                    new_fs[i + k] = fs[i]

                    new_xs[i + 1 + k] = (xs[i+1] + xs[i]) / 2
                    new_fs[i + 1 + k] = f(new_xs[i + 1 + k])
                    k += 1
                else
                    new_tot_refinements[interval + kk] = n_tot_refinements[interval]
                    new_xs[i + k] = xs[i]
                    new_fs[i + k] = fs[i]
                end
            else
                new_xs[i + k] = xs[i]
                new_fs[i + k] = fs[i]
            end
        end

        xs = new_xs
        fs = new_fs
        n_tot_refinements = new_tot_refinements
        n_points = n_points + n_new_points
        n_intervals = n_points ÷ 2
    end

    return xs
end
