/* 
A model that contains information on the tables and fields.
*/

Class constructor
	This:C1470._init()
	
	
/************ PUBLIC FUNCTIONS ************************/
Function Refresh()
	This:C1470._init()
	This:C1470._load_table_model()
	This:C1470._load_field_model()
	
	
Function GetTableFilteredList($name : Text)->$table_list : Collection
	If ($name="")
		$table_list:=This:C1470._table_model.copy()
	Else 
		$table_list:=This:C1470._table_model.query("table=:1"; $name+"@")
	End if 
	
	
Function GetFieldFilteredList($name : Text)->$field_list : Collection
	If ($name="")
		$field_list:=This:C1470._field_model.copy()
	Else 
		$field_list:=This:C1470._field_model.query("table=:1 OR field=:1"; $name+"@")
	End if 
	
	
/************ PRIVATE FUNCTIONS ************************/
Function _init()
	This:C1470._table_model:=New collection:C1472
	This:C1470._field_model:=New collection:C1472
	
	
Function _load_table_model()
	var $table_no : Integer
	For ($table_no; 1; Get last table number:C254)  // use classic since only tables with PKs are known to orda
		If (Is table number valid:C999($table_no))
			This:C1470._table_model.push(This:C1470._get_detail_for_table($table_no))
		End if 
	End for 
	This:C1470._table_model:=This:C1470._table_model.orderBy("table asc")
	
	
Function _load_field_model()
	var $table_no; $field_no : Integer
	For ($table_no; 1; Get last table number:C254)  // use classic since only tables with PKs are known to orda
		If (Is table number valid:C999($table_no))
			For ($field_no; 1; Get last field number:C255($table_no))  // use classic since only tables with PKs are known to orda
				If (Is field number valid:C1000($table_no; $field_no))
					This:C1470._field_model.push(This:C1470._get_detail_for_field($table_no; $field_no))
				End if 
			End for 
		End if 
	End for 
	This:C1470._field_model:=This:C1470._field_model.orderBy("table asc, field asc")
	
	
Function _get_detail_for_field($table_no : Integer; $field_no : Integer)->$field_detail : Object
	var $table_detail : Object
	var $type; $length : Integer
	var $isIndexed; $isUnique; $isInvisible : Boolean
	GET FIELD PROPERTIES:C258($table_no; $field_no; $type; $length; $isIndexed; $isUnique; $isInvisible)
	$table_detail:=This:C1470._table_model.query("tableNumber=:1"; $table_no)[0]
	
	$field_detail:=New object:C1471
	$field_detail.field:=Field name:C257($table_no; $field_no)
	$field_detail.name:="["+$table_detail.table+"]"+$field_detail.field
	$field_detail.table:=$table_detail.table
	$field_detail.tableNumber:=$table_no
	$field_detail.fieldNumber:=$field_no
	If ($table_detail.primaryKey_field_name#"")  // can use orda
		$field_detail.isPrimaryKey:=($table_detail.primaryKey_field_name=$field_detail.field)
	Else 
		$field_detail.isPrimaryKey:=False:C215
	End if 
	$field_detail.isIndexed:=$isIndexed
	$field_detail.isUnique:=$isIndexed
	$field_detail.isInvisible:=$isInvisible
	$field_detail.type:=This:C1470._field_type_to_text($type; $length)
	If ($field_detail.isIndexed)
		$field_detail.indexType:=Structure_IndexType2Name(Structure_GetFieldIndexType($table_no; $field_no))
		//$field_detail.indexType:="T:"+String($table_no)+" F:"+String($field_no)+" INDX:"+String(Structure_GetFieldIndexType($table_no; $field_no))
	Else 
		$field_detail.indexType:="none"
	End if 
	$field_detail.notes:=""
	
	
Function _get_detail_for_table($table_no : Integer)->$table_details : Object
	var $isInvisible; $trigger_SaveNew; $trigger_SaveRec; $trigger_DelRec : Boolean
	GET TABLE PROPERTIES:C687($table_no; $isInvisible; $trigger_SaveNew; $trigger_SaveRec; $trigger_DelRec)
	$table_details:=New object:C1471
	$table_details.table:=Table name:C256($table_no)
	$table_details.tableNumber:=$table_no
	$table_details.is_logged:=This:C1470._is_table_logged($table_no)
	$table_details.is_invisible:=$isInvisible
	$table_details.triggers:=New object:C1471
	$table_details.triggers.on_saving_new:=$trigger_SaveNew
	$table_details.triggers.on_saving_existing:=$trigger_SaveRec
	$table_details.triggers.on_deleting:=$trigger_DelRec
	$table_details.exposed_to_REST:=This:C1470._is_table_REST_enabled($table_no)
	If (ds:C1482[$table_details.table]#Null:C1517)  // orda only knows about tables with PKs
		$table_details.primaryKey_field_name:=String:C10(ds:C1482[$table_details.table].getInfo().primaryKey)
	Else 
		$table_details.primaryKey_field_name:=""
	End if 
	$table_details.num_records:=Records in table:C83(Table:C252($table_no)->)
	If ($table_details.num_records>0)
		$table_details.num_deleted:=This:C1470._get_table_deleted_count($table_no)
	Else 
		$table_details.num_deleted:=0
	End if 
	
	
Function _is_table_logged($table_no : Integer)->$table_is_logged : Boolean
	var $table_no_for_sql : Integer
	var $is_logged : Boolean
	$table_no_for_sql:=$table_no
	Begin SQL
		SELECT LOGGED
		FROM _USER_TABLES
		WHERE TABLE_ID=:$table_no_for_sql
		INTO :$is_logged;
	End SQL
	$table_is_logged:=$is_logged
	
	
Function _is_table_REST_enabled($table_no : Integer)->$is_enabled : Boolean
	var $table_no_for_sql : Integer
	var $is_set : Boolean
	$table_no_for_sql:=$table_no
	Begin SQL
		SELECT REST_AVAILABLE
		FROM _USER_TABLES
		WHERE TABLE_ID=:$table_no_for_sql
		INTO :$is_set;
	End SQL
	$is_enabled:=$is_set
	
	
Function _get_table_deleted_count($table_no : Integer)->$num_deleted : Integer
	READ ONLY:C145(*)
	ALL RECORDS:C47(Table:C252($table_no)->)
	CREATE SET:C116(Table:C252($table_no)->; "model_tableInfoSet")
	ARRAY BOOLEAN:C223($setArr; 0)
	BOOLEAN ARRAY FROM SET:C646($setArr; "model_tableInfoSet")
	CLEAR SET:C117("model_tableInfoSet")
	$num_deleted:=Size of array:C274($setArr)-Records in table:C83(Table:C252($table_no)->)+1
	ARRAY BOOLEAN:C223($setArr; 0)
	
	
Function _field_type_to_text($type : Integer; $length : Integer)->$type_as_text : Text
	Case of 
		: ($type=Is text:K8:3)
			$type_as_text:="TEXT"
			
		: ($type=Is alpha field:K8:1) & ($length>0)
			$type_as_text:="A"+String:C10($length)
			
		: ($type=Is alpha field:K8:1)
			$type_as_text:="UUID"
			
		: ($type=Is boolean:K8:9)
			$type_as_text:="BOOL"
			
		: ($type=Is time:K8:8)
			$type_as_text:="TIME"
			
		: ($type=Is date:K8:7)
			$type_as_text:="DATE"
			
		: ($type=Is real:K8:4)
			$type_as_text:="REAL"
			
		: ($type=Is longint:K8:6)
			$type_as_text:="INT 32bit"
			
		: ($type=Is integer:K8:5)
			$type_as_text:="INT 16bit"
			
		: ($type=Is BLOB:K8:12)
			$type_as_text:="BLOB"
			
		: ($type=Is object:K8:27)
			$type_as_text:="OBJ"
			
		: ($type=Is picture:K8:10)
			$type_as_text:="PICT"
			
		: ($type=Is integer 64 bits:K8:25)
			$type_as_text:="INT 64bit"
			
		Else 
			$type_as_text:="** "+String:C10($type)
	End case 
	