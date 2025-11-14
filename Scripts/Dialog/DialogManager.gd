extends Node2D

@onready var dialog_ui = $DialogUI

var npc: Node = null

func show_dialog(target_npc, text = "", options = {}):
	npc = target_npc
	if text != "":
		dialog_ui.show_dialog(npc.npc_name, text, options)
	else:
		var quest_dialog = npc.get_quest_dialog()
		if quest_dialog["text"] != "":
			dialog_ui.show_dialog(npc.npc_name, quest_dialog["text"], quest_dialog["options"])
		else:
			var dialog = npc.get_current_dialog()
			if dialog == null:
				return
			dialog_ui.show_dialog(npc.npc_name, dialog["text"], dialog["options"])

# Hide dialog
func hide_dialog():
	dialog_ui.hide_dialog()

# Dialog state management
func handle_dialog_choice(option):
	# Get current dialog branch
	var current_dialog = npc.get_current_dialog()
	if current_dialog == null:
		return

	# Linear dialog handling: when current dialog has no options, advance within the
	# same branch and SHOW the next dialog entry if it exists. Only hide/advance the
	# branch when the current dialog is the last entry.
	if current_dialog.has("options") and current_dialog["options"].size() == 0:
		var trees = npc.dialog_resource.get_npc_dialog(npc.npc_id)
		if npc.current_branch_index < trees.size():
			var dialogs = trees[npc.current_branch_index]["dialogs"]
			# find index of current dialog within the dialogs list
			var idx := -1
			for i in range(dialogs.size()):
				if dialogs[i]["state"] == current_dialog["state"]:
					idx = i
					break
			# If there is a next dialog entry in this branch, show it.
			if idx != -1 and idx + 1 < dialogs.size():
				npc.set_dialog_state(dialogs[idx + 1]["state"])
				show_dialog(npc)
				return
			# Current dialog is the last entry: end conversation and advance branch if any
			else:
				if npc.current_branch_index < trees.size() - 1:
					npc.set_dialog_tree(npc.current_branch_index + 1)
				hide_dialog()
				return
		else:
			# Branch index out of range - just hide
			if npc.current_branch_index < trees.size() - 1:
				npc.set_dialog_tree(npc.current_branch_index + 1)
			hide_dialog()
			return
	# Non-linear (choice) dialogs: use the option mapping as before
	var next_state: String = current_dialog["options"].get(option, "start")
	npc.set_dialog_state(next_state)

	# Handle state transitions (same logic as before)
	if next_state == "end":
		if npc.current_branch_index < npc.dialog_resource.get_npc_dialog(npc.npc_id).size() - 1:
			npc.set_dialog_tree(npc.current_branch_index + 1)
		hide_dialog()
	elif next_state == "exit":
		npc.set_dialog_state("start")
		hide_dialog()
	elif next_state == "give_quests":
		if npc.dialog_resource.get_npc_dialog(npc.npc_id)[npc.current_branch_index]["branch_id"] == "npc_default":
			offer_remaining_quests()
		else:
			offer_quests(npc.dialog_resource.get_npc_dialog(npc.npc_id)[npc.current_branch_index]["branch_id"])
		show_dialog(npc)
	else:
		show_dialog(npc)

# At branch, offer all currently available quests
func offer_quests(branch_id: String):
	# Debug: report which quests are considered for this branch
	print("[DialogManager] offer_quests -> branch:", branch_id)

	for quest in npc.quests:
		var can_offer := false
		if quest.state == "not_started":
			# Empty unlock_points means quest can be offered in any branch
			can_offer = quest.unlock_points.is_empty() or branch_id in quest.unlock_points
			print("[DialogManager]   quest=", quest.quest_id, "unlock_points=", quest.unlock_points, "can_offer=", can_offer)
			if can_offer:
				npc.offer_quest(quest.quest_id)
	
# At default branch, offer all previously unaccepted quests
func offer_remaining_quests():
	for quest in npc.quests:
		if quest.state == "not_started":
			npc.offer_quest(quest.quest_id)
