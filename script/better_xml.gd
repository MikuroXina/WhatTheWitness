extends Node

func parse_xml_file(file: String) -> Dictionary:
	var result = {}
	var parser = XMLParser.new()
	var error = parser.open(file)
	if error:
		print('Cannot open file %s' % file)
		return result
	while true:
		error = parser.read()
		if error:
			print('Error while reading %s' % file)
			break
		var node_name = parser.get_node_name()
		if node_name.begins_with('?xml'):
			continue
		var node_type = parser.get_node_type()
		assert(node_type == XMLParser.NODE_ELEMENT, "unexpected xml node found: %d" % node_type)
		return read_node(parser, node_name)
	return result

func read_node(parser: XMLParser, node_name: String):
	var result = {'_arr': []}
	for i in range(parser.get_attribute_count()):
		result[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
	if !parser.is_empty():
		while true:
			var error = parser.read()
			if (error):
				print('Error while reading XML node %s' % node_name)
				return result
			if (node_name.begins_with('?xml')):
				continue
			match parser.get_node_type():
				XMLParser.NODE_ELEMENT_END:
					var sub_node_name = parser.get_node_name()
					assert(sub_node_name == node_name)
					break
				XMLParser.NODE_ELEMENT:
					var sub_node_name = parser.get_node_name()
					var element = read_node(parser, sub_node_name)
					result[sub_node_name] = element
					result['_arr'].append(element)
				XMLParser.NODE_TEXT:
					var text = parser.get_node_data().strip_edges(true, true)
					if (text != ''):
						result['_text'] = text
				var sub_node_type:
					assert(sub_node_type == XMLParser.NODE_COMMENT, "unexpected xml node found: %d" % sub_node_type)

	if (result['_arr'].is_empty() and result.has('_text')):
		return result['_text']
	return result
