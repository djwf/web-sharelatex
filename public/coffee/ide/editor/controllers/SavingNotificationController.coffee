define [
	"base"
	"ide/editor/Document"
], (App, Document) ->
	App.controller "SavingNotificationController", ["$scope", "$interval", "ide", ($scope, $interval, ide) ->
		setInterval () ->
			pollSavedStatus()
		, 1000

		$(window).bind 'beforeunload', () =>
			warnAboutUnsavedChanges()

		modal = null

		$scope.docSavingStatus = {}
		pollSavedStatus = () ->
			oldStatus = $scope.docSavingStatus
			oldUnsavedCount = $scope.docSavingStatusCount
			newStatus = {}
			newUnsavedCount = 0
			maxUnsavedSeconds = 0

			for doc_id, doc of Document.openDocs
				saving = doc.pollSavedStatus()
				if !saving
					newUnsavedCount++
					if oldStatus[doc_id]?
						newStatus[doc_id] = oldStatus[doc_id]
						t = newStatus[doc_id].unsavedSeconds += 1
						if t > maxUnsavedSeconds
							maxUnsavedSeconds = t
					else
						newStatus[doc_id] = {
							unsavedSeconds: 0
							doc: ide.fileTreeManager.findEntityById(doc_id)
						}

			if newUnsavedCount > 0 and t > 15 and not modal
				modal = ide.showGenericMessageModal(
						"Connection lost"
						"Sorry, the connection to the server is down."
					)
				modal.result.finally () ->
					modal = null

			if modal and newUnsavedCount is 0
				modal.dismiss "connection back up"

			# for performance, only update the display if the old or new
			# counts of unsaved files are nonzeror.  If both old and new
			# unsaved counts are zero then we know we are in a good state
			# and don't need to do anything to the UI.
			if newUnsavedCount or oldUnsavedCount
				$scope.docSavingStatus = newStatus
				$scope.docSavingStatusCount = newUnsavedCount
				$scope.$apply()

		warnAboutUnsavedChanges = () ->
			if Document.hasUnsavedChanges()
				return "You have unsaved changes. If you leave now they will not be saved."
	]
