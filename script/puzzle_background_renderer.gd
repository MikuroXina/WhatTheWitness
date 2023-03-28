extends Control

func _draw():
	var canvas = PuzzleCanvas.new()
	canvas.current_puzzle = Gameplay.puzzle
	canvas.normalize_view(self.get_rect().size)
	canvas.draw_puzzle(self)
