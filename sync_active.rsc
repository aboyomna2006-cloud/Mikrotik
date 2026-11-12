# --- Auto Active Users Sync ---
:local ghTok ""
:local curSrc [/system script get Sync_Users_GitHub source]
:local p1 [:find $curSrc "Bearer "]
:if ([:typeof $p1] = "num") do={
    :local start ($p1 + 7)
    :local end1 [:find $curSrc "\"" $start]
    :local end2 [:find $curSrc "," $start]
    :local endPos $end1
    :if ([:typeof $end2] = "num" && $end2 < $endPos) do={ :set endPos $end2 }
    :set ghTok [:pick $curSrc $start $endPos]
}
:if ([:len $ghTok] > 10) do={
    :local allowed "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_ ()[]:+/@"
    :local actJson "["
    :local firstAct true
    :foreach i in=[/ip hotspot active find] do={
        :local uName [/ip hotspot active get $i user]
        :local ip [:tostr [/ip hotspot active get $i address]]
        :local totMB (([/ip hotspot active get $i bytes-in] + [/ip hotspot active get $i bytes-out]) / 1048576)
        :local dispName $uName
        :local uid [/ip hotspot user find name=$uName]
        :if ([:len $uid] > 0) do={
            :local comm [/ip hotspot user get $uid comment]
            :if ([:len $comm] > 0) do={
                :local toPos [:find $comm " To "]
                :if ([:typeof $toPos] = "num") do={ :set dispName [:pick $comm 0 $toPos] } else={ :set dispName $comm }
            }
        }
        :local cleanName ""
        :for j from=0 to=([:len $dispName] - 1) do={
            :local ch [:pick $dispName $j ($j + 1)]
            :if ([:typeof [:find $allowed $ch]] = "num") do={ :set cleanName ($cleanName . $ch) }
        }
        :if ([:len $cleanName] = 0) do={ :set cleanName "User" }
        :if ($firstAct = false) do={ :set actJson ($actJson . ",") }
        :set firstAct false
        :set actJson ($actJson . "{\"name\":\"" . $cleanName . "\",\"ip\":\"" . $ip . "\",\"mb\":" . $totMB . "}")
    }
    :set actJson ($actJson . "]")
    :local actUrl "https://api.github.com/repos/aboyomna2006-cloud/Mikrotik/contents/active.json"
    :local oldActSha ""
    :do {
        :local getRes [/tool fetch url=$actUrl http-header-field=("Authorization: Bearer " . $ghTok . ",User-Agent: MikroTik") as-value output=user]
        :set oldActSha ([:deserialize from=json ($getRes->"data")]->"sha")
    } on-error={}
    :local b64Act [:convert to=base64 $actJson]
    :local cleanB64Act ""
    :for k from=0 to=([:len $b64Act] - 1) do={
        :local ch [:pick $b64Act $k ($k + 1)]
        :if ($ch != "\r" && $ch != "\n") do={ :set cleanB64Act ($cleanB64Act . $ch) }
    }
    :local payloadAct ("{\"message\":\"Update active\",\"content\":\"" . $cleanB64Act . "\"")
    :if ([:len $oldActSha] > 0) do={ :set payloadAct ($payloadAct . ",\"sha\":\"" . $oldActSha . "\"") }
    :set payloadAct ($payloadAct . "}")
    /tool fetch url=$actUrl http-method=put http-header-field=("Authorization: Bearer " . $ghTok . ",User-Agent: MikroTik,Content-Type: application/json") http-data=$payloadAct keep-result=no
}
