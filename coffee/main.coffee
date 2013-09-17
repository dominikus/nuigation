# main.coffee

console.log 'hello coffeevis'

# prevent scrolling:
document.ontouchmove = (event) ->
	event.preventDefault()

# set the scene size
WIDTH = 768
HEIGHT = 960

# set some camera attributes
VIEW_ANGLE = 45
ASPECT = WIDTH / HEIGHT
NEAR = 0.1
FAR = 10000


touches = []

# get the DOM element to attach to
# - assume we've got jQuery to hand
_container = $('#container')

# create a WebGL renderer, camera and a scene
if Detector.webgl?
	renderer = new THREE.WebGLRenderer()
else
	renderer = new THREE.CanvasRenderer()

camera = new THREE.PerspectiveCamera(
	VIEW_ANGLE
	ASPECT
	NEAR
	FAR
)

scene = new THREE.Scene()

# add the camera to the scene
scene.add(camera)

# the camera starts at 0,0,0 so pull it back
camera.position.z = 500

# start the renderer
renderer.setSize(WIDTH, HEIGHT)

# attach the render-supplied DOM element
_container.append(renderer.domElement)



# add primitive box
# create the box's material
boxMaterial = new THREE.MeshBasicMaterial({
	color: 0xCC0000
	wireframe: true
	wireframeLinewidth: 2
})

width = 100
height = 100
depth = 100
box = new THREE.Mesh(
	new THREE.CubeGeometry(width, height, depth)
	boxMaterial
)

scene.add(box)

# create a point light
pointLight = new THREE.PointLight(0xFFFFFF)

# set its position
pointLight.position.x = 150
pointLight.position.y = 150
pointLight.position.z = 130

# add to the scene
scene.add(pointLight)

# set up event handlers
removeTouch = (_id) ->
	# remove from DOM
	d3.select('#overlay svg #circle' + _id)
		.remove()
	# remove from touches model
	touches = _.without(touches, _.findWhere(touches, {id: _id}))


touchstart = (evt) ->
	for touch, i in evt.originalEvent.touches
		do (touch, i) ->
			console.log "touch ##{i}: #{touch.identifier}"
			d3.select('#overlay svg').append('circle')
				.attr('cx', touch.clientX)
				.attr('cy', touch.clientY)
				.attr('r', 30)
				.attr('id', "circle#{touch.identifier}")

			touches.push({
				id: touch.identifier
				prevX: undefined
				prevY: undefined
				x: touch.clientX
				y: touch.clientY
			})

mousedown = (evt) ->
	# not much

touchmove = (evt) ->
	for touch, i in evt.originalEvent.changedTouches
		do (touch, i) ->
			d3.select('#overlay svg #circle' + touch.identifier)
				.attr('cx', touch.clientX)
				.attr('cy', touch.clientY)
			# update touches model
			touchModel = _.findWhere(touches, {id: touch.identifier})
			touchModel.prevX = touchModel.x
			touchModel.prevY = touchModel.y
			touchModel.x = touch.clientX
			touchModel.y = touch.clientY

	# remove obsolete touches
	for touchModel in touches
		do (touchModel) ->
			removeTouch(touchModel.id) if !_.findWhere(evt.originalEvent.touches, {identifier: touchModel.id})

	# move camera
	firstTouch = touches[0]
	diffX = firstTouch.x - firstTouch.prevX
	diffY = firstTouch.prevY - firstTouch.y

	camera.position.x -= diffX
	camera.position.y -= diffY
	camera.lookAt(new THREE.Vector3(0,0,0))


touchend = (evt) ->
	console.log evt
	for touch, i in evt.originalEvent.changedTouches
		do (touch, i) ->
			removeTouch(touch.identifier)

$('#overlay').on('touchstart', touchstart)
$('#overlay').on('touchmove', touchmove)
$('#overlay').on('touchend', touchend)

$('#overlay').on('mousedown', mousedown)

# draw loop
drawLoop = () ->
	if window.requestAnimationFrame?
		window.requestAnimationFrame(drawLoop)
	else
		window.setTimeout(drawLoop, 1000/24)

	renderer.render(scene, camera)


drawLoop()