<!--
Tomato GUI
Copyright (C) 2006-2007 Jonathan Zarate
http://www.polarcloud.com/tomato/
For use with Tomato Firmware only.
No part of this file may be used without permission.
LAN Access admin module by Augusto Bott
--><title><% translate("LAN Access"); %></title>
<content>
	<script type="text/javascript" src="js/wireless.jsx?_http_id=<% nv(http_id); %>"></script>
	<script type="text/javascript">
		//<% nvram ("lan_ifname,lan1_ifname,lan2_ifname,lan3_ifname,lan_access");%>

		var MAX_BRIDGE_ID = 3;

		var la = new TomatoGrid();
		la.setup = function() {
			this.init('la-grid', 'sort', 50, [
				{ type: 'checkbox', prefix: '<div class="centered">', suffix: '</div>', class: 'input-medium' },
				{ type: 'select', options: [[0, '<% translate("LAN"); %> (br0)'],[1, '<% translate("LAN2"); %> (br1)'],[2, '<% translate("LAN3"); %> (br2)'],[3, '<% translate("LAN4"); %> (br3)']], prefix: '<div class="centered">', suffix: '</div>', class: 'input-medium' },
				{ type: 'text', maxlen: 32, class: 'input-medium' },
				{ type: 'select', options: [[0, '<% translate("LAN"); %> (br0)'],[1, '<% translate("LAN2"); %> (br1)'],[2, '<% translate("LAN3"); %> (br2)'],[3, '<% translate("LAN4"); %> (br3)']], prefix: '<div class="centered">', suffix: '</div>', class: 'input-medium' },
				{ type: 'text', maxlen: 32, class: 'input-medium' },
				{ type: 'text', maxlen: 32, class: 'input-medium' }]);
			this.headerSet(['<% translate("On"); %>', '<% translate("Src"); %>', '<% translate("Src Address"); %>', '<% translate("Dst"); %>', '<% translate("Dst Address"); %>','<% translate("Description"); %>']);

			var r = nvram.lan_access.split('>');
			for (var i = 0; i < r.length; ++i) {
				if(r[i].length) {
					var l = r[i].split('<');
					l[0] *= 1;
					l[1] *= 1;
					l[3] *= 1;
					la.insertData(-1, [ l[0], l[1], l[2], l[3], l[4], l[5] ] );
				}
			}

			la.recolor();
			la.showNewEditor();
			la.resetNewEditor();
		}

		la.sortCompare = function(a, b) {
			var col = this.sortColumn;
			var da = a.getRowData();
			var db = b.getRowData();
			var r;

			switch (col) {
				case 2:	// src
				case 4:	// dst
					r = cmpIP(da[col], db[col]);
					break;
				case 0:	// on
				case 1: // src br
				case 3:	// dst br
					r = cmpInt(da[col], db[col]);
					break;
				default:
					r = cmpText(da[col], db[col]);
					break;
			}

			return this.sortAscending ? r : -r;
		}

		la.resetNewEditor = function() {
			var f = fields.getAll(this.newEditor);
			f[0].checked=true;
			f[2].value='';
			f[4].value='';
			f[5].value='';
			var total=0;
			for (var i=0; i<= MAX_BRIDGE_ID; i++) {
				var j = (i == 0) ? '' : i.toString();
				if (nvram['lan' + j + '_ifname'].length < 1) {
					f[1].options[i].disabled=true;
					f[3].options[i].disabled=true;
				} else {
					++total;
				}
			}
			if((f[1].selectedIndex == f[3].selectedIndex) && (total > 1)) {
				while (f[1].selectedIndex == f[3].selectedIndex) {
					f[3].selectedIndex = (f[3].selectedIndex%(MAX_BRIDGE_ID+1)+1);
				}
			}
			ferror.clearAll(fields.getAll(this.newEditor));
		}

		la.verifyFields = function(row, quiet) {
			var f = fields.getAll(row);

			for (var i=0; i<= MAX_BRIDGE_ID; i++) {
				var j = (i == 0) ? '' : i.toString();
				if (nvram['lan' + j + '_ifname'].length < 1) {
					f[1].options[i].disabled=true;
					f[3].options[i].disabled=true;
				}
			}

			if(f[1].selectedIndex == f[3].selectedIndex) {
				var m = '<% translate("Source and Destination interfaces must be different"); %>';
				ferror.set(f[1], m, quiet);
				ferror.set(f[3], m, quiet);
				return 0;
			}
			ferror.clear(f[1]);
			ferror.clear(f[3]);

			f[2].value = f[2].value.trim();
			f[4].value = f[4].value.trim();

			if ((f[2].value.length) && (!v_iptaddr(f[2], quiet))) return 0;
			if ((f[4].value.length) && (!v_iptaddr(f[4], quiet))) return 0;

			ferror.clear(f[2]);
			ferror.clear(f[4]);

			f[5].value = f[5].value.replace(/>/g, '_');
			if (!v_nodelim(f[5], quiet, '<% translate("Description"); %>')) return 0;

			return 1;
		}

		la.dataToView = function(data) {
			return [(data[0] != 0) ? 'On' : '',
				['<% translate("LAN"); %>', '<% translate("LAN2"); %>', '<% translate("LAN3"); %>', '<% translate("LAN4"); %>'][data[1]],
				data[2],
				['<% translate("LAN"); %>', '<% translate("LAN2"); %>', '<% translate("LAN3"); %>', '<% translate("LAN4"); %>'][data[3]],
				data[4],
				data[5] ];
		}

		la.dataToFieldValues = function (data) {
			return [(data[0] != 0) ? 'checked' : '',
				data[1],
				data[2],
				data[3],
				data[4],
				data[5] ];
		}

		la.fieldValuesToData = function(row) {
			var f = fields.getAll(row);
			return [f[0].checked ? 1 : 0,
				f[1].selectedIndex,
				f[2].value,
				f[3].selectedIndex,
				f[4].value,
				f[5].value ];
		}

		function save()
		{
			if (la.isEditing()) return;
			la.resetNewEditor();

			var fom = E('_fom');
			var ladata = la.getAllData();

			var s = '';
			for (var i = 0; i < ladata.length; ++i) {
				s += ladata[i].join('<') + '>';
			}
			fom.lan_access.value = s;

			form.submit(fom, 0);
		}

		function init() {
			la.setup();
			var c;
			if (((c = cookie.get('advanced_access_notes_vis')) != null) && (c == '1')) toggleVisibility("notes");
		}

		function toggleVisibility(whichone) {
			if (E('sesdiv_' + whichone).style.display == '') {
				E('sesdiv_' + whichone).style.display = 'none';
				E('sesdiv_' + whichone + '_showhide').innerHTML = '<i class="icon-chevron-up"></i>';
				cookie.set('advanced_access_' + whichone + '_vis', 0);
			} else {
				E('sesdiv_' + whichone).style.display='';
				E('sesdiv_' + whichone + '_showhide').innerHTML = '<i class="icon-chevron-down"></i>';
				cookie.set('advanced_access_' + whichone + '_vis', 1);
			}
		}

	</script>

	<form id="_fom" method="post" action="tomato.cgi">
	<input type="hidden" name="_nextpage" value="/#advanced-access.asp">
	<input type="hidden" name="_nextwait" value="10">
	<input type="hidden" name="_service" value="firewall-restart">
	<input type="hidden" name="lan_access">

	<div class="box">
		<div class="heading"><% translate("LAN Access Settings"); %></div>
		<div class="content">

			<table class="line-table" id="la-grid"></table>

		</div>
	</div>

	<!-- NOTES -->
	<div class="box">
		<div class="heading"><% translate("Notes"); %> <a class="pull-right" data-toggle="tooltip" title="<% translate("Hide/Show Notes"); %>" href="javascript:toggleVisibility('notes');"><span id="sesdiv_notes_showhide"><i class="icon-chevron-up"></i></span></a></div>
		<div class="section content" id="sesdiv_notes" style="display:none">

			<ul>
				<li><b><% translate("Src"); %></b> - <% translate("Source LAN bridge"); %>.</li>
				<li><b><% translate("Src Address"); %></b> <i>(<% translate("optional"); %>)</i> - <% translate("Source address allowed. Ex"); %>: "1.2.3.4", "1.2.3.4 - 2.3.4.5", "1.2.3.0/24".</li>
				<li><b><% translate("Dst"); %></b> - <% translate("Destination LAN bridge"); %>.</li>
				<li><b><% translate("Dst Address"); %></b> <i>(<% translate("optional"); %>)</i> - <% translate("Destination address inside the LAN"); %>.</li>
			</ul>

		</div>
	</div>

	<button type="button" value="<% translate("Save"); %>" id="save-button" onclick="save()" class="btn btn-primary"><% translate("Save"); %> <i class="icon-check"></i></button>
	<button type="button" value="<% translate("Cancel"); %>" id="cancel-button" onclick="javascript:reloadPage();" class="btn"><% translate("Cancel"); %> <i class="icon-cancel"></i></button>
	<span id="footer-msg" class="alert alert-warning" style="visibility: hidden;"></span>

	<script type="text/javascript">init();</script>
</content>

