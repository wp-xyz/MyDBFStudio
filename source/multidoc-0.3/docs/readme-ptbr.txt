  MultiDoc
  Um componente Lazarus para substituir a inteface padrão MDI.
  
  Copyright (C) 2007 Patrick Chevalley, http://www.ap-i.net
  Contribuções enviadas por Júnior Gonçalves, <hipernetjr@yahoo.com.br>

Licença (LGPL, inglês):

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


Descrição:
  
  Este componente permite escrever aplicações pseudo-MDI em Lazarus.
  Ele não é a implementação real da interface MDI mas dá a sua aplicação 
  a capacidade de usar muitos sub-forms redimensionáveis.
    
  Converter uma aplicação MDI é simplificado pela disponibilidade do mesmo
  componente para Delphi. Converta antes sua aplicação para MultiDoc no Delphi,
  e então converta para Lazarus.
  Isto requer algum trabalho mas em vantagem você evita a borda XP feia sobre 
  seus formulários filhos. 
  
  Este componente é exclusivamente derivado de componentes padrão de alto nível
  (TScrollBox). Ele deve trabalhar em todas as plataformas Lazarus sem mudanças.
  Veja a demonstração e o fonte do componente para mais explicações.

História:

Versão 0.3 2007/12/31 Arrumado o seguinte:
	- Através de {$IFDEF}'s o componente compila em Lazarus/Delphi sem modificações
	- Ótima movimentação. Agora o mouse não "escapa" enquanto o cursor é arrastado
	- ChildDoc é agora derivado de TFormPanel (veja suite LMDI)
	- Não é mais necessário código em cada componente ja janela filha para focar a mesma
	- É possível trocar o "tema" da barra de títulos, de acordo com o SO (veja o componente TTitleBar)

Versão 0.2 2007/01/06 Arrumado o seguinte:
	- Propriedade BorderWidth não functiona
	- Ordem dos botões errada
	- Centraliza o cursor para a barra de títulos quando movimenta o "panel"
	- Compatibilidade com Gtk2 e FPC 2.1.1
	- Travamento quando fecha uma filha usando o botão fechar
	- Licença modificada para modified LGPL

Versão 0.1 2006/01/20 Primeiro lançamento beta.
