using Images, FileIO, Colors, FixedPointNumbers, Statistics
# using ColorBrewer
#
# definition of system:
# x_{n+1} = sin(a y_n) + c cos(a x_n)
# y_{n+1} = sin(b x_n) + d cos(b y_n)

#size of the rendered canvas in pixels. it is always a square canvas
CANVAS_SIZE = 1500
#parameters governing the iterations
A=1.4
B=1.2
C=1.4
D=1.7
#number of points to render.
NUM_POINTS=Int(1e9)
#initial value
X_INIT=0 
Y_INIT=0
#proportion of the canvas to be kept as a margin
MARGIN=0.15
#file path to save to
OUT_FILE_NAME="./image_2.jpg"
#what percentile of the clifford attractor should not be completely saturated
#by color?
PERCENTILE_CLIP = 0.998
#what color should the attractor be? it will always be on a white background.
#you can invert it to black with the INVERSE parameter below.  grabbing some
#some sample color palettes from the ColorBrewer package which look nice.
#COLORS=((0.4,0.761,0.647),(0.988,0.553,0.384),(0.553,0.627,0.796))
COLOR=(0.988,0.553,0.384)
#the default is the above color (in rgb) on a white background. you can invert
#all colors using this parameter.
INVERSE=false



#these functions might be called a few hundred million times, so an if statement has
#been brought outside the function definitions to try and speed things up.
if D < C
    function create_plot_scalers(c, d, margin)
        x_range = 1 + c
        y_range = 1 + d
        norm = (2 * x_range * (1/(1-2*margin)))
        other_max = 2*y_range / norm
        less_margin = (1-other_max) / 2
        (x_range, y_range, norm, margin, less_margin)
    end
    function scale_point((x, y), (x_range, y_range, norm, margin, less_margin))
        trans_x, trans_y = x + x_range, y + y_range
        trans_x /= norm
        trans_y /= norm
        trans_x += margin
        trans_y += less_margin
        (trans_x, trans_y)
    end
else
    function create_plot_scalers(c, d, margin)
        x_range = 1 + c
        y_range = 1 + d
        norm = (2 * y_range * (1/(1-2*margin)))
        other_max = 2*x_range / norm
        less_margin = (1-other_max) / 2
        (x_range, y_range, norm, margin, less_margin)
    end
    function scale_point((x, y), (x_range, y_range, norm, margin, less_margin))
        trans_x, trans_y = x + x_range, y + y_range
        trans_x /= norm
        trans_y /= norm
        trans_y += margin
        trans_x += less_margin
        (trans_x, trans_y)
    end
end


function increment_canvas!(canvas, state, canvas_size, plot_scale_params)
    plot_x, plot_y = scale_point(state, plot_scale_params)
    plot_x *= canvas_size
    plot_y *= canvas_size 
    plot_x = floor(Int, plot_x)
    plot_y = floor(Int, plot_y)
    plot_x = canvas_size - plot_x + 1
    plot_y = canvas_size - plot_y + 1
    canvas[plot_y, plot_x] += 1
end

function update_state(a,b,c,d,(x, y))
    new_x = sin(a*y) + c*cos(a*x)
    new_y = sin(b*x) + d*cos(b*y)
    (new_x, new_y)
end

function clifford_attractor(a, b, c, d, num_points, canvas_size, margin, x_init, y_init, percentile_clip)
    plot_scale_params = create_plot_scalers(c, d, margin)
    canvas = zeros(canvas_size, canvas_size)
    state = (x_init, y_init)
    increment_canvas!(canvas, state, canvas_size, plot_scale_params)
    for step in 2:num_points
        state = update_state(a,b,c,d,state) 
        increment_canvas!(canvas, state, canvas_size, plot_scale_params)
    end
    scale = quantile(canvas[canvas.>0], percentile_clip)
    canvas/scale
end

function pixel_color_transform(pixel,(r,g,b))
    if pixel <= 0
        output = RGB{N0f8}(0.,0.,0.)
    elseif pixel <= 1
        output = RGB{N0f8}((1-r)*pixel,(1-g)*pixel,(1-b)*pixel)
    else
        output = RGB{N0f8}((1-r),(1-g),1-b)
    end
    output
end

function render_img(data,color)
    x,y = size(data)
    canvas = zeros(RGB{N0f8},x,y)
    for i in 1:x
        for j in 1:y
            canvas[i,j] = pixel_color_transform(data[i,j], color)
        end
    end
    canvas
end

function main(a=A, b=B, c=C, d=D, 
              num_points=NUM_POINTS, x_init=X_INIT, y_init=Y_INIT, 
              canvas_size=CANVAS_SIZE, margin=MARGIN, 
              out_file_name=OUT_FILE_NAME, 
              percentile_clip=PERCENTILE_CLIP, color=COLOR, inverse=INVERSE)
    output = clifford_attractor(a, b, c, d, num_points, canvas_size, margin, x_init, y_init, percentile_clip)
    img = render_img(output,color)
    if !inverse
        img = RGB{N0f8}(1.,1.,1.) .- img
    end
    save(out_file_name, img)
end

main()
