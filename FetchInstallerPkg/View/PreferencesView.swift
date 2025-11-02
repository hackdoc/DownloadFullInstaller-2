//
//  PreferencesView.swift
//
//  Created by Armin Briegel on 2021-06-15
//  Modified by Emilio P Egido on 2025-08-25

import SwiftUI

struct PreferencesView: View {
	@AppStorage(Prefs.key(.seedProgram)) var seedProgram: String = SeedProgram.noSeed.rawValue
	@AppStorage(Prefs.key(.osNameID)) var osNameID: String = OsNameID.osAll.rawValue
	@AppStorage(Prefs.key(.downloadPath)) var downloadPath: String = ""
	@AppStorage(Prefs.key(.sortOrder)) var sortOrder: String = SortOrder.dateDescending.rawValue
	@EnvironmentObject var sucatalog: SUCatalog

	let labelWidth = 100.0
	var body: some View {
		VStack(spacing: 16) {
			// 第一行：操作系统选择
			HStack(alignment: .center) {
				Picker("osNameID", selection: $osNameID) {
					ForEach(OsNameID.allCases) { osName in
						Text(osName.rawValue).font(.body)
					}
				}
				.pickerStyle(MenuPickerStyle())
				
				Text(NSLocalizedString(" in catalog", comment: "")).font(.body)
				
				if #available(macOS 14.0, *) {
					Picker(selection: $seedProgram, label: EmptyView()) {
						ForEach(SeedProgram.allCases) { program in
							Text(program.rawValue).font(.body)
						}
					}
					.pickerStyle(MenuPickerStyle())
					.onChange(of: seedProgram) { sucatalog.load() }
					.onChange(of: osNameID) { sucatalog.load() }
				} else {
					Picker(selection: $seedProgram, label: EmptyView()) {
						ForEach(SeedProgram.allCases) { program in
							Text(program.rawValue).font(.body)
						}
					}
					.pickerStyle(MenuPickerStyle())
					.onChange(of: seedProgram) { _ in
						sucatalog.load()
					}
					.onChange(of: osNameID) { _ in
						sucatalog.load()
					}
				}
			}
			
			// 第二行：排序选项
			HStack(alignment: .center) {
				Text(NSLocalizedString("Sort Order", comment: "")).font(.body)
				
				Picker(selection: $sortOrder, label: EmptyView()) {
					ForEach(SortOrder.allCases) { order in
						Text(getSortOrderDisplayName(order)).font(.body)
					}
				}
				.pickerStyle(MenuPickerStyle())
				.onChange(of: sortOrder) { _ in
					sucatalog.sortInstallers()
				}
			}
		}
		.padding()
		.liquidGlass(intensity: .subtle)
		.frame(width: 400.0, height: 100.0) // 增加高度以容纳所有选项
		.labelsHidden()
	}
	
	// 获取排序选项的显示名称
	private func getSortOrderDisplayName(_ order: SortOrder) -> String {
		switch order {
		case .dateDescending:
			return NSLocalizedString("Date (Newest First)", comment: "")
		case .dateAscending:
			return NSLocalizedString("Date (Oldest First)", comment: "")
		case .versionOrder:
			return NSLocalizedString("Version Order", comment: "")
		}
	}
}

struct PreferencesView_Previews: PreviewProvider {
	static var previews: some View {
		PreferencesView()
	}
}

