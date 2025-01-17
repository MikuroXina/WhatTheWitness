extends Node

class FilamentNail:
	var pos: Vector2

class FilamentSolution:
	var started: bool
	var start_pos: Vector2
	var end_pos: Vector2
	var path_points: Array
	var extra_nails: Array # around the start point

	func try_start_solution_at(pos: Vector2, circle_radius: float) -> bool:
		if started:
			started = false
			return false
		started = true
		start_pos = pos
		end_pos = pos
		path_points = [[pos, -1]]
		extra_nails.clear()
		for i in range(8):
			var angle_point = i * PI / 4
			extra_nails.append(pos + Vector2.from_angle(angle_point) * circle_radius)
		return true

	func det(v1: Vector2, v2: Vector2) -> float:
		return v1.x * v2.y - v2.x * v1.y

	func try_continue_solution(nails, delta) -> float:
		return try_continue_single_step(nails, delta)


	func try_continue_single_step(fixed_nails, delta) -> float:
		if not started:
			return 0.0
		var original_step = delta.length()

		# add nails
		var nails = []
		nails += fixed_nails
		if len(path_points) >= 2:
			nails += extra_nails
		# print(original_step)
		if original_step < 1e-10:
			return 1.0
		var min_delta_step = delta.length()
		for i in range(len(path_points) - 1):
			var col = Geometry2D.segment_intersects_segment (path_points[i][0],
				path_points[i + 1][0], end_pos, end_pos + delta)
			if col != null:
				min_delta_step = min(min_delta_step, (end_pos - col).length())
				delta = delta / delta.length() * (min_delta_step - 1e-6)
		var last_nail_pos = path_points[-1][0]
		var last_bend_direction = path_points[-1][1]
		var second_to_last_nail_pos = start_pos if len(path_points) <= 1 else path_points[-2][0]
		var nearest_collision_forward = INF
		var nearest_collision_far = INF
		var nearest_collision_nail = null
		var nearest_collision_bend_direction = 0
		for target_nail_pos in nails:
			var bend_pos = last_nail_pos
			if (target_nail_pos == last_nail_pos):
				bend_pos = second_to_last_nail_pos
			var nail_vector = target_nail_pos - bend_pos
			var nail_dist = nail_vector.length()
			assert(nail_dist >= 1e-6)
			var nail_dir = nail_vector.normalized()
			var filament_vector = end_pos - bend_pos
			var new_filament_vector = filament_vector + delta
			if not Geometry2D.point_is_inside_triangle(target_nail_pos, bend_pos, end_pos, end_pos + delta):
				continue # out-of-bound test

			var old_cross = det(filament_vector, nail_dir)
			var new_cross = det(new_filament_vector, nail_dir)
			var ok = false
			var old_dir
			if target_nail_pos == last_nail_pos:
				old_dir = last_bend_direction
				if ((old_dir == 0 and new_cross > 0) or
					(old_dir == 1 and new_cross < 0)):
					ok = true
			else:
				# print(target_nail_pos, '|', old_cross, '|', new_cross, '||', filament_vector, new_filament_vector, '||', nail_dir)

				old_dir = 0 if old_cross < 0 else 1
				if (
					(old_dir == 0 and new_cross >= -1e-6) or
					(old_dir == 1 and new_cross <= 1e-6)
				):
					ok = true
			if ok:
				var sin_a = abs(old_cross) / (filament_vector.length() + 1e-10)
				var sin_b = abs(det(delta.normalized(), nail_dir))
				var forward = filament_vector.length() / sin_b * sin_a
				var far = (target_nail_pos - last_nail_pos).length()
				# print(target_nail_pos, ':', forward, ',', far, 'ok')
				if (nearest_collision_forward > forward + 1e-6 or
					(abs(nearest_collision_forward - forward) < 1e-6) and
					far > nearest_collision_far):
					nearest_collision_bend_direction = 1 - old_dir
					nearest_collision_forward = forward
					nearest_collision_far = far
					nearest_collision_nail = target_nail_pos
		if nearest_collision_nail != null:
			if nearest_collision_nail == last_nail_pos and len(path_points) > 1:
				# print('pop!')
				path_points.pop_back()
			else:
				# print('push!')
				path_points.push_back([nearest_collision_nail, nearest_collision_bend_direction])
		if delta.length() > nearest_collision_forward:
			delta = delta / delta.length() * (nearest_collision_forward + 1e-6)
		var moved_percentage = delta.length() / original_step
		# print(moved_percentage, '!!')
		if moved_percentage > 1e-6:
			end_pos += delta
			return moved_percentage
		return 0.0
