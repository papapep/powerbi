let
	credencial=Record.Field(fnGetToken(),"token") as text,
    url = "https://XXXXXXXXXX",
    cua_url = "XXXXXXXXXXXXXXXX?api_key=" & credencial,
    dataIniciMes = Date.StartOfMonth(DateTime.LocalNow() as datetime) as any,
	dataMigMes = Date.AddDays(dataIniciMes,15),
    dataFiMes = Date.EndOfMonth(DateTime.LocalNow() as datetime) as any,
    dataAvui = DateTime.LocalNow() as datetime,
    dataInici1M = Date.AddMonths(Date.StartOfMonth(DateTime.LocalNow() as datetime) as any, -1),
    dataMigMes1M = Date.AddDays(dataInici1M,15),
    dataInici2M =Date.AddMonths(Date.StartOfMonth(DateTime.LocalNow() as datetime) as any, -2),
    dataMigMes2M = Date.AddDays(dataInici2M,15),
	if ()
    query = "{
			""from"":"""& DateTime.ToText(dataMigMes, [Format="yyyy-MM-dd HH:mm:ss.fff"])&""",
			""to"": """& DateTime.ToText(dataFiMes, [Format="yyyy-MM-dd HH:mm:ss.fff"])&""",
			""onlyUnprocessed"":false,
			""vehicles"":""null"",
			""drivers"":""null"",
			""alarms"":[800,900],
			""severityLevels"":[1]
			}",
	Source = Json.Document(
        Web.Contents(
            url, 
            [
                RelativePath= cua_url, 
                Headers=[
                    #"Content-Type"="application/json"
                ], 
                Content= Text.ToBinary(query)
            ]
        )
    ),
    occurrences = Source[occurrences],
    #"Converted to Table" = Table.FromList(occurrences, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"severityLevel", "severityName", "startLatitude", "startLongitude", "id", "typeId", "tagName", "definitionId", "definitionName", "vehicleId", "licensePlate", "driverId", "driverName", "started", "placeNameStart", "placeNameEnd", "organizationRestrictions", "rawData", "severityLevelId", "endLatitude", "endLongitude", "ended"}, {"severityLevel", "severityName", "startLatitude", "startLongitude", "id", "typeId", "tagName", "definitionId", "definitionName", "vehicleId", "licensePlate", "driverId", "driverName", "started", "placeNameStart", "placeNameEnd", "organizationRestrictions", "rawData", "severityLevelId", "endLatitude", "endLongitude", "ended"}),
    #"Filtered Rows" = Table.SelectRows(#"Expanded Column1", each ([severityName] = "Alarma Informativa")),
    #"Split Column by Delimiter" = Table.SplitColumn(#"Filtered Rows", "licensePlate", Splitter.SplitTextByDelimiter("-", QuoteStyle.Csv), {"licensePlate.1", "licensePlate.2"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Split Column by Delimiter",{{"licensePlate.1", type text}, {"licensePlate.2", type text}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"licensePlate.1", "calca"}, {"licensePlate.2", "Matrícula"}}),
    #"Split Column by Delimiter1" = Table.SplitColumn(#"Renamed Columns", "ended", Splitter.SplitTextByDelimiter("T", QuoteStyle.Csv), {"ended.1", "ended.2"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Split Column by Delimiter1",{{"ended.1", type date}, {"ended.2", type time}}),
    #"Inserted Parsed JSON" = Table.AddColumn(#"Changed Type1", "JSON", each Json.Document([rawData])),
    #"Expanded JSON" = Table.ExpandRecordColumn(#"Inserted Parsed JSON", "JSON", {"AreaType", "JsonControlAreaId", "IDArea", "IsIgnitionOn", "Ignition", "Area"}, {"AreaType", "JsonControlAreaId", "IDArea", "IsIgnitionOn", "Ignition", "Area"}),
    #"Renamed Columns1" = Table.RenameColumns(#"Expanded JSON",{{"ended.1", "endedDate"}, {"ended.2", "endedTime"}}),
    #"Removed Columns" = Table.RemoveColumns(#"Renamed Columns1",{"rawData", "organizationRestrictions"}),
    #"Split Column by Delimiter2" = Table.SplitColumn(#"Removed Columns", "started", Splitter.SplitTextByDelimiter("T", QuoteStyle.Csv), {"started.1", "started.2"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Split Column by Delimiter2",{{"started.1", type date}, {"started.2", type time}}),
    #"Renamed Columns2" = Table.RenameColumns(#"Changed Type2",{{"started.1", "startedDate"}, {"started.2", "startedTime"}}),
    #"Replaced Value" = Table.ReplaceValue(#"Renamed Columns2","Sortida d'àrea definida","Sortida",Replacer.ReplaceText,{"definitionName"}),
    #"Replaced Value1" = Table.ReplaceValue(#"Replaced Value","Entrada en àrea definida","Entrada",Replacer.ReplaceText,{"definitionName"}),
    #"Renamed Columns3" = Table.RenameColumns(#"Replaced Value1",{{"definitionName", "EntSort"}}),
    #"Filtered Rows1" = Table.SelectRows(#"Renamed Columns3", each true)
in
    #"Filtered Rows1"
