#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;~ #Warn ; Recommended for catching common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

global breite
global höhe
global werte
global summen

#include solver.ahk

breite:=10
load()

if not höhe
	inputbox, höhe, Höhe, ohne Summenreihe

if not (höhe >1)
{
	MsgBox du dummkopf!
	ExitApp
}

loop, % höhe
{
	zeile := a_index
	gui,add,text,xm Y+10 w50,
	loop, % breite
	{
		spalte := a_index
		gui,add,edit,X+10 yp w80 vwert_%zeile%_%spalte%
		
	}
}
gui,add,text,xm Y+20 w50, Summe
loop, % breite
{
	spalte := a_index
	gui,add,edit,X+10 yp w80 vsumme_%spalte%
	
}

gui,add,button,xm Y+20 w50 gsave, save
gui,add,button,X+10 yp w50 gguisolve, solve
gui,show

fillDataIntoGui()
return

fillDataIntoGui(values = "")
{
	global
	if not values
		values:=werte
	loop, % höhe
	{
		zeile := a_index
		loop, % breite
		{
			spalte := a_index
			if IsObject(values[zeile][spalte])
			{
				str:="_"
				loop 10
				{
					if (values[zeile][spalte][a_index -1])
						str.= (a_index -1)
				}
				Gui, Font, norm italic  
				guicontrol,font,wert_%zeile%_%spalte%
				guicontrol,,wert_%zeile%_%spalte%, % str
			}
			else
			{
				Gui, Font, norm bold  
				guicontrol,font,wert_%zeile%_%spalte%
				guicontrol,,wert_%zeile%_%spalte%, % values[zeile][spalte]
				
			}
		}
	}
	loop, % breite
	{
		spalte := a_index
		guicontrol,,summe_%spalte%, % summen[spalte]
	}
	
}

getDataFromGUI()
{
	global
	werte:=[]
	summen:=[]

	loop, % höhe
	{
		zeile := a_index
		werte[zeile]:=[]
		loop, % breite
		{
			spalte := a_index
			guicontrolget,temp,,wert_%zeile%_%spalte%
			IfInString,temp,_
				temp:=""
			werte[zeile][spalte]:=temp
		}
	}
	loop, % breite
	{
		spalte := a_index
		guicontrolget,temp,,summe_%spalte%
		summen[spalte]:=temp
	}
}

guisolve()
{
	getDataFromGUI()
	solve()
	;~ fillDataIntoGui()
	
}

save()
{
	getDataFromGUI()
	content := ""
	loop, % höhe
	{
		zeile := a_index
		loop, % breite
		{
			spalte := a_index
			content.="#" werte[zeile][spalte] " "
		}
		content.="`n"
	}
	loop, % breite
	{
		spalte := a_index
		content.="~" summen[spalte] " "
	}
	FileDelete,save.txt
	FileAppend,%content%,save.txt
}

load()
{
	werte:=[]
	summen:=[]
	
	FileRead, content, save.txt
	loop,parse,content, % "`n", "`r"
	{
		if not a_loopfield
			continue
		
		zeile := a_index
		if (substr(a_loopfield, 1,1) = "#")
			werte[zeile]:=[]
		
		loop,parse,A_LoopField, % " ", "`r"
		{
			spalte := a_index
			if (substr(a_loopfield, 1,1) = "#")
			{
				werte[zeile][spalte]:=substr(A_LoopField,2)
			}
			else if (substr(a_loopfield, 1,1) = "~")
			{
				summen[spalte]:=substr(A_LoopField,2)
			}
		}
	}
	
	höhe:=werte.MaxIndex()
}