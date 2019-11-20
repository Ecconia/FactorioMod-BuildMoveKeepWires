local active_players = {}

-- TODO: Support normal wires (setting?)
script.on_event("ref-move-key-seq",
	function(event)
		local player = game.players[event.player_index]
		local selected = player.selected
		if selected then
			if selected.name == 'entity-ghost' then
				player.print({"cannot-do-ghost-blocks"})
				-- TODO: Support ghost entities
			else
				-- Fix, if its not an item, it cannot be places in the cursor.
				-- TODO: Get ingridients and check them/that? (If thats a thing)
				if not game.item_prototypes[selected.name] then
					active_players[player.name] = nil
					return
				end
				--player.cursor_stack.clear() -- Remove this stack, to replace it. TODO: DON'T DESTROY IT!!!
				player.cursor_stack.set_stack({name = selected.name}) -- TODO: Same issue as above
				-- TODO: Apparently, only put a ghost block there.

				active_players[player.name] = {entity = selected, init = false}
			end
		end
	end
)

script.on_event(defines.events.on_built_entity,
	function(event)
		local player = game.players[event.player_index]
		local my_object = active_players[player.name]
		if my_object then
			local new_entity = event.created_entity
			local old_entity = my_object.entity
			new_entity.copy_settings(old_entity)
			for _, connection in pairs(old_entity.circuit_connection_definitions) do
				-- Fix, if the connection was to itself:
				if connection.target_entity == old_entity then
					connection.target_entity = new_entity
				end
				-- Fix, if wire cannot be placed for distance reasons, abort, but keep modi alive 
				if not new_entity.connect_neighbour(connection) then
					player.print({"wire-does-not-reach"})
					new_entity.destroy()
					my_object.init = false -- Rearm this placement.
					return
				end
			end

			active_players[player.name] = nil
			-- TODO: Support ghost entities
			old_entity.destroy()
		end
	end
)

script.on_event(defines.events.on_player_cursor_stack_changed,
	function(event)
		local player = game.players[event.player_index]
		local my_object = active_players[player.name]
		if my_object then
			if my_object.init then
				active_players[player.name] = nil
				-- TODO: Fix duplication (my manual fix inventory :/)
				-- TODO: Fix trigger by crafting (removing stack by 1 and setting init to false)
				return
			else
				my_object.init = true;
			end
		end
	end
)
