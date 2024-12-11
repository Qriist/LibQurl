#Requires AutoHotkey v2.0
#Include "%A_ScriptDir%"
#Include %a_scriptdir%\..\lib\LibQurl.ahk
#Include %a_scriptdir%\..\lib\Aris\G33kDude\cjson.ahk
SetWorkingDir(A_ScriptDir "\..")
curl := LibQurl(A_WorkingDir "\bin\libcurl.dll")

;NOTE: .MultiInit() is automatically called during .register(), 
;but can be invoked multiple times to group downloads as desired
first_multi_handle := curl.MultiInit()

;Make a few easy_handles and put them in the multi pool
;We're creating excess to test a few features in one go.
easy1 := curl.EasyInit()
easy2 := curl.EasyInit()
easyA := curl.EasyInit()
easyB := curl.EasyInit()
easy_ := curl.EasyInit()

;these are a combined ~176mb
Download1 := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-01.pgn.zst"  
Download2 := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-02.pgn.zst"
DownloadA := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-03.pgn.zst"
DownloadB := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-04.pgn.zst"
Download_ := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-05.pgn.zst"
Download1B := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-06.pgn.zst" ;downloaded later
Download2B := "https://database.lichess.org/standard/lichess_db_standard_rated_2013-07.pgn.zst" ;downloaded later

;prepare the downloads per each handle. Once finalized, add the easy_handles to the multi pool
curl.SetOpt("URL",Download1,easy1), curl.WriteToFile(A_ScriptDir "\09.easy1.pgn.zst",easy1)    ;,curl.ReadyAsync(easy1)
curl.SetOpt("URL",Download2,easy2), curl.WriteToFile(A_ScriptDir "\09.easy2.pgn.zst",easy2)    ;,curl.ReadyAsync(easy2)
curl.SetOpt("URL",DownloadA,easyA), curl.WriteToFile(A_ScriptDir "\09.easyA.pgn.zst",easyA)    ;,curl.ReadyAsync(easyA)
curl.SetOpt("URL",DownloadB,easyB), curl.WriteToFile(A_ScriptDir "\09.easyB.pgn.zst",easyB)    ;,curl.ReadyAsync(easyB)
curl.SetOpt("URL",Download_,easy_), curl.WriteToFile(A_ScriptDir "\09.easy_.pgn.zst",easy_)    ;,curl.ReadyAsync(easy_)

;can also add the easy_handles in batch as an array of values
easyHandles := [easy1,easy2,easyA,easyB,easy_]
curl.ReadyAsync(easyHandles)    ;multi_handle param not required *here* as it defaults to the last created

;download a priority file synchronously, automatically removing it from the multipool if needed
curl.Sync(easy_)

;transfer 2 items to a different multi pool
second_multi_handle := curl.MultiInit()
curl.SwapMultiPools([easyA,easyB],first_multi_handle,second_multi_handle)

;Download from both pools simultaneously
loop {
    check := 0
    check += curl.Async(first_multi_handle)
    check += curl.Async(second_multi_handle)
} until !check

;test reusing the handles
curl.SetOpt("URL",Download1B,easy1), curl.WriteToFile(A_ScriptDir "\09.easy1B.pgn.zst",easy1)
curl.SetOpt("URL",Download2B,easy2), curl.WriteToFile(A_ScriptDir "\09.easy2B.pgn.zst",easy2)
curl.ReadyAsync([easy1,easy2],first_multi_handle)
loop {
    check := 0
    check += curl.Async(first_multi_handle)
}   until !check

;known hashes of the downloads (might change server-side in the future, verify on failure)
SHA256 := Map()
SHA256["09.easy_"] := "f044607c9f565831524dbedfd474100c8604dba008600bfaf1b7a48ced74c17b"
SHA256["09.easy1"] := "aa40b3671fa3cf1072eb182892cd90b0e1e003a4a5943492f64b77e7f3fd1635"
SHA256["09.easy2"] := "c136acdf343293c45252906fee91e3b561fb26a936979f52dbe04bb649a2fd86"
SHA256["09.easyA"] := "89da64fc3c1fe3bfd571d7f626232189f3259aa728b46ea81e5cb8f3fdb34b9e"
SHA256["09.easyB"] := "11c795d3c81c49fa97cd958b0984c044410c78ad90f454ed08abb57ab7d00d52"
SHA256["09.easy1B"] := "fef2a88dcdb386eacf02800d119737079d9be154ed986007fe4f8b5bb76741e8"
SHA256["09.easy2B"] := "51da6cfc0a6aa6e5f71a21691650dad0dc1adcabb5ba9e7de36f559ffb17a1f7"

;hash the files
failed := sha256.count
for k,v in SHA256{
    filePath := A_ScriptDir "\" k ".pgn.zst"
    if !FileExist(filepath){
        continue
    }
    actual := HashFile(filepath,4)  ;SHA265
    if (v = actual)
        failed -= 1
}

FileOpen(a_scriptdir "\09.results.txt","w").write(failed " failed hashes")

ExitApp

; HashFile by Deo
; https://autohotkey.com/board/topic/66139-ahk-l-calculating-md5sha-checksum-from-file/
; Modified for AutoHotkey v2 by lexikos.

#Requires AutoHotkey v2.0-beta

/*
HASH types:
1 - MD2
2 - MD5
3 - SHA
4 - SHA256
5 - SHA384
6 - SHA512
*/
HashFile(filePath, hashType:=2)
{
	static PROV_RSA_AES := 24
	static CRYPT_VERIFYCONTEXT := 0xF0000000
	static BUFF_SIZE := 1024 * 1024 ; 1 MB
	static HP_HASHVAL := 0x0002
	static HP_HASHSIZE := 0x0004
	
    switch hashType {
        case 1: hash_alg := (CALG_MD2 := 32769)
        case 2: hash_alg := (CALG_MD5 := 32771)
        case 3: hash_alg := (CALG_SHA := 32772)
        case 4: hash_alg := (CALG_SHA_256 := 32780)
        case 5: hash_alg := (CALG_SHA_384 := 32781)
        case 6: hash_alg := (CALG_SHA_512 := 32782)
        default: throw ValueError('Invalid hashType', -1, hashType)
    }
	
	f := FileOpen(filePath, "r")
    f.Pos := 0 ; Rewind in case of BOM.
    
    HCRYPTPROV() => {
        ptr: 0,
        __delete: this => this.ptr && DllCall("Advapi32\CryptReleaseContext", "Ptr", this, "UInt", 0)
    }
    
	if !DllCall("Advapi32\CryptAcquireContextW"
				, "Ptr*", hProv := HCRYPTPROV()
				, "Uint", 0
				, "Uint", 0
				, "Uint", PROV_RSA_AES
				, "UInt", CRYPT_VERIFYCONTEXT)
		throw OSError()
	
    HCRYPTHASH() => {
        ptr: 0,
        __delete: this => this.ptr && DllCall("Advapi32\CryptDestroyHash", "Ptr", this)
    }
    
	if !DllCall("Advapi32\CryptCreateHash"
				, "Ptr", hProv
				, "Uint", hash_alg
				, "Uint", 0
				, "Uint", 0
				, "Ptr*", hHash := HCRYPTHASH())
        throw OSError()
	
	read_buf := Buffer(BUFF_SIZE, 0)
	
	While (cbCount := f.RawRead(read_buf, BUFF_SIZE))
	{
		if !DllCall("Advapi32\CryptHashData"
					, "Ptr", hHash
					, "Ptr", read_buf
					, "Uint", cbCount
					, "Uint", 0)
			throw OSError()
	}
	
	if !DllCall("Advapi32\CryptGetHashParam"
				, "Ptr", hHash
				, "Uint", HP_HASHSIZE
				, "Uint*", &HashLen := 0
				, "Uint*", &HashLenSize := 4
				, "UInt", 0) 
        throw OSError()
		
    bHash := Buffer(HashLen, 0)
	if !DllCall("Advapi32\CryptGetHashParam"
				, "Ptr", hHash
				, "Uint", HP_HASHVAL
				, "Ptr", bHash
				, "Uint*", &HashLen
				, "UInt", 0 )
        throw OSError()
	
	loop HashLen
		HashVal .= Format('{:02x}', (NumGet(bHash, A_Index-1, "UChar")) & 0xff)
	
	return HashVal
}