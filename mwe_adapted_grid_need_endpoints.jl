using Plots

f(x) = x^2
∇f(x) = 2x

forward_difference(f, x, h) = (f(x+h) - f(x)) / h

signed_error(f, ▽f, x, h, scheme) = scheme(f, x, h) - ▽f(x)

error_plot = plot(;xaxis=:log, yaxis=:log)

plotme(h) = abs(signed_error(f, ∇f, 1, h, forward_difference))

(h_start, h_end) = (1e-20, 0.1)
max_recursions = 70

h_eval = Plots.adapted_grid(plotme, (h_start, h_end); max_recursions=max_recursions)
y_eval = plotme.(h_eval)
#y_eval[y_eval .== 0] .= 1e-20 # unrelated Plots issue: https://github.com/JuliaPlots/Plots.jl/issues/2046

plot!(error_plot, plotme, h_start, h_end
  ;
  label="current adapted_grid, max_recursions: $(max_recursions)",
  marker=:x,
  markersize=1.0,
  linewidth=4.0
)

include("adapted_grid.jl")

h_eval = gg_adapted_grid(plotme, (h_start, h_end); max_recursions=max_recursions)
y_eval = plotme.(h_eval)

plot!(error_plot, h_eval, y_eval,
  ;
  label="gg_adapted_grid, max_recursions: $(max_recursions)",
  marker=:o,
  markersize=0.1,
)
