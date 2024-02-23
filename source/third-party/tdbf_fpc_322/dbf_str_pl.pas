unit dbf_str;

interface

{$I dbf_common.inc}
{$I dbf_str.inc}

implementation

initialization

  STRING_FILE_NOT_FOUND               := 'Otw�rz: brak pliku: "%s".';
  STRING_VERSION                      := 'TDbf V%d.%d';
  STRING_FEATURE_NOT_SUPPORTED_THIS_TABLELEVEL := 'Ta funkcja nie jest obs�ugiwana w typie bazy (tablelevel) %d';

  STRING_RECORD_LOCKED                := 'Rekord zablokowany.';
  STRING_WRITE_ERROR                  := 'Wyst�pi� b��d podczas zapisu. (Brak miejsca na dysku?)';
  STRING_KEY_VIOLATION                := 'Konflikt klucza. (Klucz jest obecny w pliku).'+#13+#10+
                                         'Indeks: %s'+#13+#10+'Rekord=%d Klucz=''%s''.';

  STRING_INVALID_DBF_FILE             := 'Nieprawid�owy plik DBF.';
  STRING_INVALID_DBF_FILE_FIELDERROR  := 'Nieprawid�owy plik DBF. B��dna definicja pola.'; 
  STRING_FIELD_TOO_LONG               := 'Warto�� jest za d�uga: %d znak�w (maksymalnie %d).';
  STRING_INVALID_FIELD_COUNT          := 'Nieprawid�owa liczba p�l: %d (dozwolone 1 do 4095).';
  STRING_INVALID_FIELD_TYPE           := 'Nieprawid�owy typ pola ''%s'' dla pola ''%s''.';
  STRING_INVALID_VCL_FIELD_TYPE       := 'Nie mo�na utworzy� pola "%s", typ pola VCL %x nie jest obs�ugiwany przez DBF.';


  STRING_INDEX_BASED_ON_UNKNOWN_FIELD := 'Indeks bazuje na nieznanym polu "%s".';
  STRING_INDEX_BASED_ON_INVALID_FIELD := 'Typ pola "%s" jest nieprawid�owy dla indeks�w.';
  STRING_INDEX_EXPRESSION_TOO_LONG    := 'Wynik indeksu dla "%s" jest za d�ugi, >100 znak�w (%d).';
  STRING_INVALID_INDEX_TYPE           := 'Nieprawid�owy typ indeksu: tylko string lub float.';
  STRING_CANNOT_OPEN_INDEX            := 'Nie mog� otworzy� indeksu: "%s".';
  STRING_TOO_MANY_INDEXES             := 'Nie mog� utworzy� indeksu: za du�o indeks�w w pliku.';
  STRING_INDEX_NOT_EXIST              := 'Indeks "%s" nie istnieje.';
  STRING_NEED_EXCLUSIVE_ACCESS        := 'Wymagany jest wy��czny dost�p dla tej operacji.';
end.

