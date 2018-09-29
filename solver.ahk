#include <object>

FileDelete,log.txt
debug(text)
{
	FileAppend,% text  "`n",log.txt
}

solve()
{
	stacks:=[]
	stackHypothesis:=[]
	
	firstStack:=ObjFullyClone(werte)
	loop, % höhe
	{
		zeile := a_index
		loop, % breite
		{
			spalte := a_index
			if (firstStack[zeile][spalte] >= 0)
				continue
			firstStack[zeile][spalte]:=[]
			loop,10
				firstStack[zeile][spalte][a_index-1] := true
		}
	}
	
	stacks.push(firstStack)
	stackHypothesis.push("")
	fillDataIntoGui(firstStack)
	currentStack:=firstStack
	currentHypothesis:=""
	debug("Ersten Stack erstellt")
	Loop
	{
		Loop
		{
			copy:=objFullyClone(currentStack)
			; eingrenzen, welche Werte erlaubt sind
			allSolved := eingrenzen(currentStack)
			errorFound := fehlersuche(currentStack)
			if (allSolved && not errorFound)
			{
				MsgBox, 4, Lösung gefunden,Weitersuchen, um evtl. mehere Lösungen zu finden?
			IfMsgBox,yes
				{
					errorFound:="Manuelle Fortführung der Suche"
				}
			}
			if (errorFound)
			{
				wrongHypothesis := stackHypothesis.pop()
				wrongStack := stacks.pop()
				if (not wrongHypothesis)
				{
					MsgBox Keine Lösung gefunden :-(
					return
				}
				debug("Stack " stacks.MaxIndex() " ist fehlerhaft. Hypothese war " wrongHypothesis.zeile " x " wrongHypothesis.spalte " = " wrongHypothesis.wert " Fehlermeldung: " errorFound)
				currentStack:=stacks[stacks.MaxIndex()]
				currentHypothesis:=stackHypothesis[stackHypothesis.MaxIndex()]
				currentStack[wrongHypothesis.zeile][wrongHypothesis.spalte][wrongHypothesis.wert] := false
				continue
			}
			
			fillDataIntoGui(currentStack)
			if (ObjFullyCompare_oneDir(currentStack,copy))
				break
			if allSolved
				break
			;~ MsgBox
		}
		
		
		if allSolved
			break
		
		; Brute Force: Hypothese machen
		currentStack:=objFullyClone(currentStack)
		hypothesis:=solver_makeHypothesis(currentStack)
		stacks.push(currentStack)
		stackHypothesis.push(hypothesis)
		debug("Neuen Stack " stacks.MaxIndex() " erstellt. Hypothese: " hypothesis.zeile " x " hypothesis.spalte " = " hypothesis.wert)
		solver_CorrectEntriesWithOneSolution(currentStack)
	}
	
}

eingrenzen(stack)
{
	extendedWerte:=[]
	
	loop
	{
		copy:=objFullyClone(stack)
		
		;Jede Zeile enthält die Zahlen 0 bis 9
		loop, % höhe
		{
			zeile := a_index
			blockedNumbersInLine:=solver_getExistingNumbersInLine(stack[zeile])
			loop, % breite
			{
				spalte := a_index
				if (IsObject(stack[zeile][spalte]))
				{
					solver_deleteImpossibleNumbersFromField(stack[zeile][spalte], blockedNumbersInLine)
				}
			}
		}
		
		;Einträge, wo nur noch eine Zahl erlaubt ist, festlegen
		solver_CorrectEntriesWithOneSolution(stack)
		
		;Benachbarte Zahlen dürfen nicht gleich sein
		loop, % höhe
		{
			zeile := a_index
			blockedNumbersInLine:=[]
			loop, % breite
			{
				spalte := a_index
				if (IsObject(stack[zeile][spalte]))
				{
					neighBours:=solver_getNeighborNumbers(zeile, spalte, stack)
					solver_deleteImpossibleNumbersFromField(stack[zeile][spalte],neighBours)
				}
			}
		}
		
		;Einträge, wo nur noch eine Zahl erlaubt ist, festlegen
		solver_CorrectEntriesWithOneSolution(stack)
		
		if (ObjFullyCompare_oneDir(stack,copy))
			break
	}
	fillDataIntoGui(stack)
	
	;Die Zahlen einer Spalte müssen die Summen ergeben
	loop, % breite
	{
		spalte := a_index
		oneSpalte := solver_getSpalte(spalte, stack)
		possibleValues := solver_getPossibleNumberFromSum(oneSpalte, summen[spalte])
		loop, % höhe
		{
			zeile := a_index
			if (IsObject(stack[zeile][spalte]))
			{
				for oneValue, onePossible in possibleValues[zeile]
				{
					if not (onePossible)
					{
						stack[zeile][spalte][oneValue] := false
					}
				}
			}
		}
	}
	
	;Einträge, wo nur noch eine Zahl erlaubt ist, festlegen
	solver_CorrectEntriesWithOneSolution(stack)
	fillDataIntoGui(stack)
	
	;Prüfen, ob alles gelöst ist
	allSolved:=true
	loop, % höhe
	{
		zeile := a_index
		loop, % breite
		{
			spalte := a_index
			if (IsObject(stack[zeile][spalte]))
			{
				allSolved := false
			}
		}
	}
	return allSolved
}

solver_CorrectEntriesWithOneSolution(stack)
{
	loop, % höhe
	{
		zeile := a_index
		loop, % breite
		{
			spalte := a_index
			possibleNumber := ""
			if (IsObject(stack[zeile][spalte]))
			{
				loop,10
				{
					if (stack[zeile][spalte][a_index -1] == true)
					{
						if (possibleNumber >= -1)
							possibleNumber := -1
						else
							possibleNumber := a_index -1
					}
				}
				if (possibleNumber >= 0)
				{
					stack[zeile][spalte] := possibleNumber
				}
			}
		}
	}
}

solver_getPossibleNumberFromSum(spaltenWerte, summe)
{
	retval := []
	vorhandeneSumme := 0
	retPossibleValues:=Object()
	loop, % höhe
	{
		zeile := a_index
		if (not IsObject(spaltenWerte[zeile]))
		{
			vorhandeneSumme += spaltenWerte[zeile]
		}
		retPossibleValues[zeile]:=[]
	}
	restSumme := summe - vorhandeneSumme
	
	;Alle Kombinationen durchgehen und prüfen, ob sie die Summe ergeben
	;~ debug("spaltenWerte: " strobj(spaltenWerte))
	solver_getPossibleNumberFromSum_iterate(spaltenWerte, 1, summe, retPossibleValues)
	
	return retPossibleValues
}

solver_getPossibleNumberFromSum_iterate(offeneWerte, startIndex, summe, retPossibleValues)
{
	;~ debug("startindex: " startIndex " -  summe: " summe)
	retVal:=false
	if isobject(offeneWerte[startIndex])
	{
		spaltenWerte:=offeneWerte[startIndex]
	}
	else
	{
		spaltenWerte:=[]
		loop,10
			spaltenWerte[a_index-1] := false
		spaltenWerte[offeneWerte[startIndex]] := true
	}
	for oneWert, onePossible in spaltenWerte
	{
		if (onePossible)
		{
			if (IsObject(offeneWerte[startIndex + 1]) or offeneWerte[startIndex + 1] >= 0)
			{
				possible := solver_getPossibleNumberFromSum_iterate(offeneWerte, startIndex + 1, summe - oneWert, retPossibleValues)
			}
			else
			{
				possible := (summe == oneWert)
			}
			retVal := retVal or possible
			retPossibleValues[startIndex][oneWert] := retPossibleValues[startIndex][oneWert] or possible
			;~ debug("index: " startIndex " -  wert: " oneWert " ist " possible)
		}
	}
	return retVal
}

solver_getNeighborNumbers(zeile, spalte, stack)
{
	retval:=[]
	
	zuPrüfen:=[]
	if (zeile > 1)
	{
		zuPrüfen.push({zeile: zeile-1, spalte: spalte})
		if (spalte > 1)
			zuPrüfen.push({zeile: zeile-1, spalte: spalte-1})
		if (spalte < breite)
			zuPrüfen.push({zeile: zeile-1, spalte: spalte+1})
	}
	if (spalte > 1)
		zuPrüfen.push({zeile: zeile, spalte: spalte-1})
	if (spalte < breite)
		zuPrüfen.push({zeile: zeile, spalte: spalte+1})
	if (zeile < höhe)
	{
		zuPrüfen.push({zeile: zeile+1, spalte: spalte})
		if (spalte > 1)
			zuPrüfen.push({zeile: zeile+1, spalte: spalte-1})
		if (spalte < breite)
			zuPrüfen.push({zeile: zeile+1, spalte: spalte+1})
	}
	for oneIndex, oneZuPrüfen in zuPrüfen
	{
		if (not IsObject(stack[oneZuPrüfen.zeile][oneZuPrüfen.spalte]))
		{
			retval.push(stack[oneZuPrüfen.zeile][oneZuPrüfen.spalte])
		}
	}
	return retval
}


solver_getExistingNumbersInLine(line, spalteAusschließen = "")
{
	retval:=[]
	loop, % breite
	{
		spalte := a_index
		if (not IsObject(line[spalte]))
		{
			if not (spalteAusschließen == spalte)
				retval.push(line[spalte])
		}
	}
	return retval
}

solver_makeHypothesis(stack)
{
	;nach einem ungelösten Feld mit den wenigsten Möglichkeiten suchen
	BestCount := 10
	BestHypothesis := {}
	loop, % höhe
	{
		zeile := a_index
		loop, % breite
		{
			spalte := a_index
			if (IsObject(stack[zeile][spalte]))
			{
				countValues := 0
				oneValue := ""
				loop 10
				{
					if (stack[zeile][spalte][a_index -1])
					{
						countValues += 1
						if (oneValue = "")
						{
							oneValue := a_index -1
						}
					}
				}
				if (countValues < BestCount)
				{
					BestHypothesis := {zeile: zeile, spalte: spalte, wert: oneValue}
					BestCount:=countValues
				}
			}
		}
	}
	stack[BestHypothesis.zeile][BestHypothesis.spalte]:= BestHypothesis.wert
	return BestHypothesis
}


solver_getSpalte(spalte, stack)
{
	retval:=[]
	loop, % höhe
	{
		zeile := a_index
		retval.push(stack[zeile][spalte])
	}
	return retval
}

solver_deleteImpossibleNumbersFromField(field, numbers)
{
	for oneindex, oneNumber in numbers
	{
		field[oneNumber] := false
	}
	
}

fehlersuche(stack)
{
	berechneteSummen:=[]
	loop, % breite
		berechneteSummen[a_index]:=0
	loop, % höhe
	{
		zeile := a_index
		loop, % breite
		{
			spalte := a_index
			if (IsObject(stack[zeile][spalte]))
			{
				anyNumberAllowed:=false
				loop 10
				{
					if (stack[zeile][spalte][a_index -1])
					{
						anyNumberAllowed := true
					}
				}
				if not anyNumberAllowed
					return "Wert " zeile " x " spalte " ist leer"
				
				
				berechneteSummen[spalte] :=""
			}
			else if not (stack[zeile][spalte] >=0)
			{
				return "Wert " zeile " x " spalte " ist  leer"
			}
			else
			{
				numbers :=solver_getNeighborNumbers(zeile, spalte, stack)
				for oneIndex, oneNumber in numbers
					if (stack[zeile][spalte] = oneNumber)
						return "Wert " zeile " x " spalte " hat einen Nachbar mit gleichem Wert"
					
				numbers :=solver_getExistingNumbersInLine(stack[zeile], spalte)
				for oneIndex, oneNumber in numbers
					if (stack[zeile][spalte] = oneNumber)
						return "Wert " zeile " x " spalte " hat einen Liniennachbar mit gleichem Wert"
					
				berechneteSummen[spalte] += stack[zeile][spalte]
			}
		}
	}
	loop, % breite
	{
		if (berechneteSummen[a_index] >= 0 and berechneteSummen[a_index] != summen[a_index])
			return "Summe in Spalte " spalte " ist falsch (" berechneteSummen[a_index] " statt " summen[a_index]
	}
	
	return false
}

