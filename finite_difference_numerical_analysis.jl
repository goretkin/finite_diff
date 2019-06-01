include("adapted_grid.jl")

using Plots
pyplot()
f(x) = x^2
∇f(x) = 2x

forward_difference(f, x, h) = (f(x+h) - f(x)) / h

central_difference(f, x, h) = (f(x+h) - f(x-h)) / 2h

imag_forward_difference(f, x, h) = imag((f(x + h * im) - f(x)) / h)

signed_error(f, ▽f, x, h, scheme) = scheme(f, x, h) - ▽f(x)



schemes = [forward_difference, central_difference, imag_forward_difference]

BigFloat128(x) = BigFloat(x; precision=128)

floats = [Float16, Float32, Float64]#, BigFloat128]

stuff = []
function doit()
  global stuff
  error_plot = plot(;xaxis=:log, yaxis=:log)
  x_at = 1

  for scheme in schemes, float in floats
    @show string(float)
    @show string(scheme)
    smallest_nonzero = nextfloat(float(0))
    x_at = float(x_at) # just to avoid relying on number type promotion rules
    @assert typeof(smallest_nonzero) == typeof(x_at) == typeof(smallest_nonzero + x_at)
    #plot_start = smallest_nonzero
    plot_start = eps(float(1)) / 100
    plot_end = float(0.1)
    plotme(h) = abs(signed_error(f, ∇f, x_at, h, scheme))
    h_eval = gg_adapted_grid(plotme, (plot_start, plot_end))
    push!(stuff, (x=h_eval, y=plotme.(h_eval)))
    y = plotme.(h_eval)
    y[y .== 0] .= nextfloat(zero(eltype(y))) # Plots errors with 0 in log plot
    plot!(error_plot, h_eval,
      y
      #plot_start, plot_end
      #plot_start:0.000001:plot_end
      ;
      marker="dot",
      markersize=0.1,
      label="$scheme, $float")
  end
  error_plot
end

doit()



