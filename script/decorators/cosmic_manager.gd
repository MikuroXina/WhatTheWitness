extends "../decorator.gd"

var rule = 'cosmic-manager'

var alien_vertices = []
var house_vertices = []
var is_angry = {}
var vertex_detectors = {}

const VACANT = -1

func add_alien(v):
	alien_vertices.append(v)
	is_angry[v] = false

func add_house(v):
	house_vertices.append(v)

func draw_above_solution(canvas, id, _owner_type, puzzle, solution):
	if (
		solution == null or
		not solution.started or
		len(solution.state_stack[-1].event_properties) <= id
	):
		return

	var states = solution.state_stack[-1].event_properties[id]

	for alien_v in alien_vertices:
		if not (alien_v in states):
			continue
		if states[alien_v] != VACANT:
			var background_color = puzzle.background_color
			puzzle.vertices[alien_v].decorator.draw_alien(canvas, puzzle, puzzle.vertices[alien_v].pos,
				Color(background_color, 0.7))
		if is_angry[alien_v]:
			puzzle.vertices[alien_v].decorator.draw_anger(canvas, puzzle, puzzle.vertices[alien_v].pos, Color.BLACK)
	for house_v in house_vertices:
		if not (house_v in states):
			continue
		if states[house_v] == VACANT:
			continue
		var alien_v = states[house_v]
		var alien_color = puzzle.vertices[alien_v].decorator.color
		puzzle.vertices[house_v].decorator.draw_house(canvas, puzzle, puzzle.vertices[house_v].pos,
			alien_color, true)

	for way in range(puzzle.n_ways):
		if not (-way - 1 in states):
			continue
		var way_state = states[-way - 1]
		if way_state == VACANT:
			continue
		var alien_v = way_state
		var alien_color = puzzle.vertices[alien_v].decorator.color
		if alien_color == null:
			continue
		canvas.add_circle(solution.get_current_way_position(puzzle, way),
			puzzle.line_width * 0.3,
			alien_color
		)

func prepare_validation(validator, states):
	var puzzle = validator.puzzle
	for alien_v in alien_vertices:
		if not (alien_v in states):
			continue
		if states[alien_v] != VACANT:
			continue
		var vertex = puzzle.vertices[alien_v]
		var response = validator.add_decorator(vertex.decorator, vertex.pos, alien_v)
		validator.push_vertex_decorator_response(alien_v, response)
	for house_v in house_vertices:
		if not (house_v in states):
			continue
		var vertex = puzzle.vertices[house_v]
		var response = validator.add_decorator(vertex.decorator, vertex.pos, house_v)
		if states[house_v] != VACANT:
			var alien_v = states[house_v]
			var alien_color = puzzle.vertices[alien_v].decorator.color
			response.color = alien_color
		response.decorator.satisfied = states[house_v] != VACANT
		validator.push_vertex_decorator_response(house_v, response)

	for way in range(puzzle.n_ways):
		if not (-way - 1 in states):
			continue
		var way_state = states[-way - 1]
		if way_state == VACANT:
			continue
		var way_end_v = validator.solution.vertices[way][-1]
		var alien_v = way_state
		var response = validator.add_decorator(puzzle.vertices[alien_v].decorator, puzzle.vertices[way_end_v].pos, way_end_v)
		validator.push_vertex_decorator_response(way_end_v, response)

func init_property(puzzle: Graph.Puzzle, _solution_state, _start_vertex):
	var states = {}
	for alien_v in alien_vertices:
		states[alien_v] = VACANT
		vertex_detectors[alien_v] = []
		var facet = puzzle.vertices[alien_v].linked_facet
		if facet != null:
			for edge_tuple in facet.edge_tuples:
				vertex_detectors[alien_v].append(puzzle.edge_detector_node[edge_tuple])
		is_angry[alien_v] = false
	for house_v in house_vertices:
		states[house_v] = VACANT
		vertex_detectors[house_v] = []
		var facet = puzzle.vertices[house_v].linked_facet
		if facet == null:
			continue
		for edge_tuple in facet.edge_tuples:
			vertex_detectors[house_v].append(puzzle.edge_detector_node[edge_tuple])

	for way in range(puzzle.n_ways):
		states[-way - 1] = VACANT
	return states

func transit(puzzle: Graph.Puzzle, vertices: Array, old_state: Dictionary):
	var new_state = {}
	for key in old_state:
		new_state[key] = old_state[key]
	for way in range(puzzle.n_ways):
		var way_state = new_state[-way - 1]
		var passing_vertex_id = vertices[way][-1]
		if way_state == VACANT:
			var aliens_on_board = []
			for alien_v in alien_vertices:
				if new_state[alien_v] != VACANT:
					continue
				if passing_vertex_id in vertex_detectors[alien_v]:
					aliens_on_board.append(alien_v)
			if len(aliens_on_board) == 1:
				is_angry[aliens_on_board[0]] = false
				way_state = aliens_on_board[0]
				new_state[aliens_on_board[0]] = -2 - way
			else:
				for alien_v in aliens_on_board:
					is_angry[alien_v] = true
		else: # occupied
			for house_v in house_vertices:
				if new_state[house_v] != VACANT:
					continue
				if not (passing_vertex_id in vertex_detectors[house_v]):
					continue
				var alien_v = way_state
				var house_color = puzzle.vertices[house_v].decorator.color
				var alien_color = puzzle.vertices[alien_v].decorator.color
				if house_color == Color.BLACK or house_color == alien_color:
					new_state[alien_v] = house_v
					new_state[house_v] = alien_v
					way_state = -1
					break
		new_state[-way - 1] = way_state
	return new_state

func property_to_string(states: Dictionary) -> String:
	var result = PackedStringArray()
	for v in states:
		result.append('%d:%d' % [v, states[v]])
	return ','.join(result)

func string_to_property(string: String) -> Dictionary:
	if string.is_empty():
		return {}

	var result = string.split(',')
	var states = {}
	for state_string in result:
		var key_value = state_string.split(':')
		if len(key_value) == 2:
			states[int(key_value[0])] = int(key_value[1])
	return states
