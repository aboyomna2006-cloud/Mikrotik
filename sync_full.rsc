# ==========================================
# Sync_Users_GitHub (RouterOS v7)
# Syncs both users.json & active.json (Token-Safe)
# ==========================================

:local ghToken "PUT_TOKEN_HERE"
:local ghUser "aboyomna2006-cloud"
:local ghRepo "Mikrotik"
:local authHeader ("Authorization: Bearer " . $ghToken . ",Accept: application/vnd.github+json,User-Agent: MikroTik-RouterOS")

# ------------------------------------------
# 1. تجهيز ورفع users.json
# ------------------------------------------
:local allowed "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _-.:/+()[]@"
:local jsonStr "["
:local first true

:foreach uid in=[/ip hotspot user find] do={
    :local uName [/ip hotspot user get $uid name]
    :if ($uName != "default-trial") do={
        :local uComm [/ip hotspot user get $uid comment]
        :local uProf [/ip hotspot user get $uid profile]
        :local rawLim [/ip hotspot user get $uid limit-bytes-total]
        :local uLim 0
        :if ([:typeof $rawLim] = "num") do={
            :if ($rawLim > 0) do={
                :set uLim ($rawLim / 1073741824)
            }
        }
        :local uUsed (([/ip hotspot user get $uid bytes-in] + [/ip hotspot user get $uid bytes-out]) / 1048576)
        :local uDis [/ip hotspot user get $uid disabled]
        :local idStr [:tostr $uid]

        :local cleanName ""
        :local hasNonAscii false
        :for i from=0 to=([:len $uName] - 1) do={
            :local ch [:pick $uName $i ($i + 1)]
            :if ([:typeof [:find $allowed $ch]] = "num") do={
                :set cleanName ($cleanName . $ch)
            } else={
                :set hasNonAscii true
            }
        }
        :if ($hasNonAscii = true) do={
            :set cleanName ("Arabic_User_" . $idStr)
        }

        :local cleanComm ""
        :for i from=0 to=([:len $uComm] - 1) do={
            :local ch [:pick $uComm $i ($i + 1)]
            :if ([:typeof [:find $allowed $ch]] = "num") do={
                :set cleanComm ($cleanComm . $ch)
            } else={
                :set cleanComm ($cleanComm . " ")
            }
        }

        :if ($first = false) do={ :set jsonStr ($jsonStr . ",") }
        :set first false

        :set jsonStr ($jsonStr . "{\"id\":\"" . $idStr . "\",\"n\":\"" . $cleanName . "\",\"c\":\"" . $cleanComm . "\",\"p\":\"" . $uProf . "\",\"l\":" . $uLim . ",\"u\":" . $uUsed . ",\"d\":" . [:tostr $uDis] . "}")
    }
}
:set jsonStr ($jsonStr . "]")

:local b64Content [:convert to=base64 $jsonStr]
:local apiUrl ("https://api.github.com/repos/" . $ghUser . "/" . $ghRepo . "/contents/users.json")

:local fileSha ""
:do {
    :local getRes [/tool fetch url=$apiUrl http-method=get http-header-field=$authHeader as-value output=user]
    :local getJson [:deserialize from=json ($getRes->"data")]
    :set fileSha ($getJson->"sha")
} on-error={}

:local payload ""
:if ([:len $fileSha] > 0) do={
    :set payload ("{\"message\":\"Sync users\",\"content\":\"" . $b64Content . "\",\"sha\":\"" . $fileSha . "\"}")
} else={
    :set payload ("{\"message\":\"Create users.json\",\"content\":\"" . $b64Content . "\"}")
}
/tool fetch url=$apiUrl http-method=put http-header-field=$authHeader http-data=$payload keep-result=no

# ------------------------------------------
# 2. تجهيز ورفع active.json (المشتركين النشطين)
# ------------------------------------------
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
            :if ([:typeof $toPos] = "num") do={
                :set dispName [:pick $comm 0 $toPos]
            } else={
                :local devPos [:find $comm " (Dev:"]
                :if ([:typeof $devPos] = "num") do={
                    :set dispName [:pick $comm 0 $devPos]
                } else={
                    :set dispName $comm
                }
            }
        }
    }

    :local cleanName ""
    :for j from=0 to=([:len $dispName] - 1) do={
        :local ch [:pick $dispName $j ($j + 1)]
        :if ([:typeof [:find $allowed $ch]] = "num") do={
            :set cleanName ($cleanName . $ch)
        }
    }
    :if ([:len $cleanName] = 0) do={ :set cleanName "User" }

    :if ($firstAct = false) do={ :set actJson ($actJson . ",") }
    :set firstAct false
    :set actJson ($actJson . "{\"name\":\"" . $cleanName . "\",\"ip\":\"" . $ip . "\",\"mb\":" . $totMB . "}")
}
:set actJson ($actJson . "]")

:local b64Act [:convert to=base64 $actJson]
:local actUrl ("https://api.github.com/repos/" . $ghUser . "/" . $ghRepo . "/contents/active.json")

:local actSha ""
:do {
    :local getActRes [/tool fetch url=$actUrl http-method=get http-header-field=$authHeader as-value output=user]
    :local getActJson [:deserialize from=json ($getActRes->"data")]
    :set actSha ($getActJson->"sha")
} on-error={}

:local payloadAct ""
:if ([:len $actSha] > 0) do={
    :set payloadAct ("{\"message\":\"Sync active\",\"content\":\"" . $b64Act . "\",\"sha\":\"" . $actSha . "\"}")
} else={
    :set payloadAct ("{\"message\":\"Create active.json\",\"content\":\"" . $b64Act . "\"}")
}
/tool fetch url=$actUrl http-method=put http-header-field=$authHeader http-data=$payloadAct keep-result=no
