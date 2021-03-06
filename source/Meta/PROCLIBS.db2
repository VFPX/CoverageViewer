*--------------------------------------------------------------------------------------------------------------------------------------------------------
* (ES) AUTOGENERADO - ??ATENCI?N!! - ??NO PENSADO PARA EJECUTAR!! USAR SOLAMENTE PARA INTEGRAR CAMBIOS Y ALMACENAR CON HERRAMIENTAS SCM!!
* (EN) AUTOGENERATED - ATTENTION!! - NOT INTENDED FOR EXECUTION!! USE ONLY FOR MERGING CHANGES AND STORING WITH SCM TOOLS!!
*--------------------------------------------------------------------------------------------------------------------------------------------------------
*< FOXBIN2PRG: Version="1.19" SourceFile="proclibs.dbf" /> (Solo para binarios VFP 9 / Only for VFP 9 binaries)
*


<TABLE>
	<MemoFile></MemoFile>
	<CodePage>1252</CodePage>
	<LastUpdate></LastUpdate>
	<Database></Database>
	<FileType>0x00000030</FileType>
	<FileType_Descrip>Visual FoxPro</FileType_Descrip>

	<FIELDS>
		<FIELD>
			<Name>FNAME</Name>
			<Type>C</Type>
			<Width>20</Width>
			<Decimals>0</Decimals>
			<Null>.F.</Null>
			<NoCPTran>.F.</NoCPTran>
			<Field_Valid_Exp></Field_Valid_Exp>
			<Field_Valid_Text></Field_Valid_Text>
			<Field_Default_Value></Field_Default_Value>
			<Table_Valid_Exp></Table_Valid_Exp>
			<Table_Valid_Text></Table_Valid_Text>
			<LongTableName></LongTableName>
			<Ins_Trig_Exp></Ins_Trig_Exp>
			<Upd_Trig_Exp></Upd_Trig_Exp>
			<Del_Trig_Exp></Del_Trig_Exp>
			<TableComment></TableComment>
			<Autoinc_Nextval>0</Autoinc_Nextval>
			<Autoinc_Step>0</Autoinc_Step>
		</FIELD>
		<FIELD>
			<Name>FDIR</Name>
			<Type>C</Type>
			<Width>12</Width>
			<Decimals>0</Decimals>
			<Null>.F.</Null>
			<NoCPTran>.F.</NoCPTran>
			<Field_Valid_Exp></Field_Valid_Exp>
			<Field_Valid_Text></Field_Valid_Text>
			<Field_Default_Value></Field_Default_Value>
			<Table_Valid_Exp></Table_Valid_Exp>
			<Table_Valid_Text></Table_Valid_Text>
			<LongTableName></LongTableName>
			<Ins_Trig_Exp></Ins_Trig_Exp>
			<Upd_Trig_Exp></Upd_Trig_Exp>
			<Del_Trig_Exp></Del_Trig_Exp>
			<TableComment></TableComment>
			<Autoinc_Nextval>0</Autoinc_Nextval>
			<Autoinc_Step>0</Autoinc_Step>
		</FIELD>
		<FIELD>
			<Name>TYPE</Name>
			<Type>C</Type>
			<Width>1</Width>
			<Decimals>0</Decimals>
			<Null>.F.</Null>
			<NoCPTran>.F.</NoCPTran>
			<Field_Valid_Exp></Field_Valid_Exp>
			<Field_Valid_Text></Field_Valid_Text>
			<Field_Default_Value></Field_Default_Value>
			<Table_Valid_Exp></Table_Valid_Exp>
			<Table_Valid_Text></Table_Valid_Text>
			<LongTableName></LongTableName>
			<Ins_Trig_Exp></Ins_Trig_Exp>
			<Upd_Trig_Exp></Upd_Trig_Exp>
			<Del_Trig_Exp></Del_Trig_Exp>
			<TableComment></TableComment>
			<Autoinc_Nextval>0</Autoinc_Nextval>
			<Autoinc_Step>0</Autoinc_Step>
		</FIELD>
		<FIELD>
			<Name>EXCLUDE</Name>
			<Type>L</Type>
			<Width>1</Width>
			<Decimals>0</Decimals>
			<Null>.F.</Null>
			<NoCPTran>.F.</NoCPTran>
			<Field_Valid_Exp></Field_Valid_Exp>
			<Field_Valid_Text></Field_Valid_Text>
			<Field_Default_Value></Field_Default_Value>
			<Table_Valid_Exp></Table_Valid_Exp>
			<Table_Valid_Text></Table_Valid_Text>
			<LongTableName></LongTableName>
			<Ins_Trig_Exp></Ins_Trig_Exp>
			<Upd_Trig_Exp></Upd_Trig_Exp>
			<Del_Trig_Exp></Del_Trig_Exp>
			<TableComment></TableComment>
			<Autoinc_Nextval>0</Autoinc_Nextval>
			<Autoinc_Step>0</Autoinc_Step>
		</FIELD>
		<FIELD>
			<Name>DONT_LOAD</Name>
			<Type>L</Type>
			<Width>1</Width>
			<Decimals>0</Decimals>
			<Null>.F.</Null>
			<NoCPTran>.F.</NoCPTran>
			<Field_Valid_Exp></Field_Valid_Exp>
			<Field_Valid_Text></Field_Valid_Text>
			<Field_Default_Value></Field_Default_Value>
			<Table_Valid_Exp></Table_Valid_Exp>
			<Table_Valid_Text></Table_Valid_Text>
			<LongTableName></LongTableName>
			<Ins_Trig_Exp></Ins_Trig_Exp>
			<Upd_Trig_Exp></Upd_Trig_Exp>
			<Del_Trig_Exp></Del_Trig_Exp>
			<TableComment></TableComment>
			<Autoinc_Nextval>0</Autoinc_Nextval>
			<Autoinc_Step>0</Autoinc_Step>
		</FIELD>
	</FIELDS>

	<IndexFiles>

		<IndexFile Type="Structural" >

			<INDEXES>
				<INDEX>
					<TagName>FULLNAME</TagName>
					<TagType>REGULAR</TagType>
					<Key>UPPER(FNAME)</Key>
					<Filter></Filter>
					<Order>ASCENDING</Order>
					<Collate>MACHINE</Collate>
				</INDEX>
			</INDEXES>
		</IndexFile>

	</IndexFiles>


	<RECORDS>

		<RECORD>
			<FNAME>handlerr.prg</FNAME>
			<FDIR>libs\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>kstrings.prg</FNAME>
			<FDIR>libs\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>mainproc.prg</FNAME>
			<FDIR>libs\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>chkplibs.prg</FNAME>
			<FDIR>src\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>kosfiles.prg</FNAME>
			<FDIR>libs\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>proccntl.prg</FNAME>
			<FDIR>src\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>appcntls.vcx</FNAME>
			<FDIR>libs\</FDIR>
			<TYPE>V</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>datafile.prg</FNAME>
			<FDIR>src\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>appform.vcx</FNAME>
			<FDIR>src\</FDIR>
			<TYPE>V</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>zsetmgr.prg</FNAME>
			<FDIR>libs\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.T.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>zarrays.prg</FNAME>
			<FDIR>libs\</FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

		<RECORD>
			<FNAME>main.prg</FNAME>
			<FDIR></FDIR>
			<TYPE>P</TYPE>
			<EXCLUDE>.F.</EXCLUDE>
			<DONT_LOAD>.F.</DONT_LOAD>
		</RECORD>

	</RECORDS>


</TABLE>

