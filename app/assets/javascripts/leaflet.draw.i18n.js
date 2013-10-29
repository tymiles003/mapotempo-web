(function (window, document, undefined) {

L.drawLocal = {
	draw: {
		toolbar: {
			actions: {
				title: I18n.t('leaflet_draw.draw.toolbar.actions.title'),
				text: I18n.t('leaflet_draw.draw.toolbar.actions.text'),
			},
			buttons: {
				polyline: I18n.t('leaflet_draw.draw.toolbar.buttons.polyline'),
				polygon: I18n.t('leaflet_draw.draw.toolbar.buttons.polygon'),
				rectangle: I18n.t('leaflet_draw.draw.toolbar.buttons.rectangle'),
				circle: I18n.t('leaflet_draw.draw.toolbar.buttons.circle'),
				marker: I18n.t('leaflet_draw.draw.toolbar.buttons.marker')
			}
		},
		handlers: {
			circle: {
				tooltip: {
					start: I18n.t('leaflet_draw.draw.handlers.circle.tooltip.start')
				}
			},
			marker: {
				tooltip: {
					start: I18n.t('leaflet_draw.draw.handlers.marker.tooltip.start')
				}
			},
			polygon: {
				tooltip: {
					start: I18n.t('leaflet_draw.draw.handlers.polygon.tooltip.start'),
					cont: I18n.t('leaflet_draw.draw.handlers.polygon.tooltip.cont'),
					end: I18n.t('leaflet_draw.draw.handlers.polygon.tooltip.end'),
				}
			},
			polyline: {
				error: I18n.t('leaflet_draw.draw.handlers.polyline.error'),
				tooltip: {
					start: I18n.t('leaflet_draw.draw.handlers.polyline.tooltip.start'),
					cont: I18n.t('leaflet_draw.draw.handlers.polyline.tooltip.cont'),
					end: I18n.t('leaflet_draw.draw.handlers.polyline.tooltip.end')
				}
			},
			rectangle: {
				tooltip: {
					start: I18n.t('leaflet_draw.draw.handlers.rectangle.tooltip.start')
				}
			},
			simpleshape: {
				tooltip: {
					end: I18n.t('leaflet_draw.draw.handlers.simpleshape.tooltip.end')
				}
			}
		}
	},
	edit: {
		toolbar: {
			actions: {
				save: {
					title: I18n.t('leaflet_draw.edit.toolbar.actions.save.title'),
					text: I18n.t('leaflet_draw.edit.toolbar.actions.save.text')
				},
				cancel: {
					title: I18n.t('leaflet_draw.edit.toolbar.actions.cancel.title'),
					text: I18n.t('leaflet_draw.edit.toolbar.actions.cancel.text')
				}
			},
			buttons: {
				edit: I18n.t('leaflet_draw.edit.toolbar.buttons.edit'),
				editDisabled: I18n.t('leaflet_draw.edit.toolbar.buttons.editDisabled'),
				remove: I18n.t('leaflet_draw.edit.toolbar.buttons.remove'),
				removeDisabled: I18n.t('leaflet_draw.edit.toolbar.buttons.removeDisabled')
			}
		},
		handlers: {
			edit: {
				tooltip: {
					text: I18n.t('leaflet_draw.edit.handlers.edit.tooltip.text'),
					subtext: I18n.t('leaflet_draw.edit.handlers.edit.tooltip.subtext')
				}
			},
			remove: {
				tooltip: {
					text: I18n.t('leaflet_draw.edit.handlers.remove.tooltip.text')
				}
			}
		}
	}
};

}(this, document));
