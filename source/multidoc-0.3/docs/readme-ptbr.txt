  MultiDoc
  Um componente Lazarus para substituir a inteface padr�o MDI.
  
  Copyright (C) 2007 Patrick Chevalley, http://www.ap-i.net
  Contribu��es enviadas por J�nior Gon�alves, <hipernetjr@yahoo.com.br>

Licen�a (LGPL, ingl�s):

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version with the following modification:

  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,and
  to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a
  module which is not derived from or based on this library. If you modify
  this library, you may extend this exception to your version of the library,
  but you are not obligated to do so. If you do not wish to do so, delete this
  exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


Descri��o:
  
  Este componente permite escrever aplica��es pseudo-MDI em Lazarus.
  Ele n�o � a implementa��o real da interface MDI mas d� a sua aplica��o 
  a capacidade de usar muitos sub-forms redimension�veis.
    
  Converter uma aplica��o MDI � simplificado pela disponibilidade do mesmo
  componente para Delphi. Converta antes sua aplica��o para MultiDoc no Delphi,
  e ent�o converta para Lazarus.
  Isto requer algum trabalho mas em vantagem voc� evita a borda XP feia sobre 
  seus formul�rios filhos. 
  
  Este componente � exclusivamente derivado de componentes padr�o de alto n�vel
  (TScrollBox). Ele deve trabalhar em todas as plataformas Lazarus sem mudan�as.
  Veja a demonstra��o e o fonte do componente para mais explica��es.

Hist�ria:

Vers�o 0.3 2007/12/31 Arrumado o seguinte:
	- Atrav�s de {$IFDEF}'s o componente compila em Lazarus/Delphi sem modifica��es
	- �tima movimenta��o. Agora o mouse n�o "escapa" enquanto o cursor � arrastado
	- ChildDoc � agora derivado de TFormPanel (veja suite LMDI)
	- N�o � mais necess�rio c�digo em cada componente ja janela filha para focar a mesma
	- � poss�vel trocar o "tema" da barra de t�tulos, de acordo com o SO (veja o componente TTitleBar)

Vers�o 0.2 2007/01/06 Arrumado o seguinte:
	- Propriedade BorderWidth n�o functiona
	- Ordem dos bot�es errada
	- Centraliza o cursor para a barra de t�tulos quando movimenta o "panel"
	- Compatibilidade com Gtk2 e FPC 2.1.1
	- Travamento quando fecha uma filha usando o bot�o fechar
	- Licen�a modificada para modified LGPL

Vers�o 0.1 2006/01/20 Primeiro lan�amento beta.
