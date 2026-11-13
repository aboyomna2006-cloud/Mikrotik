# ==========================================
# Telegram_Receiver (RouterOS v7)
# Silent Lock + 5x Clean Google Ping + Clean HTML
# ==========================================

:global botBusy
:if ($botBusy = true) do={ :return "" }
:set botBusy true

:do {
    :local botToken "9010171304:AAGo8QbUxcWaC6Y4wWb2i8Wb0M6YvJHLYZM"
    :local adminChatId "486915427"

    :global lastUpdateId
    :if ([:typeof $lastUpdateId] != "num") do={ :set lastUpdateId 0 }

    :local apiUrl ("https://api.telegram.org/bot" . $botToken . "/getUpdates?offset=" . ($lastUpdateId + 1) . "&timeout=4")
    :local res [/tool fetch url=$apiUrl as-value output=user]

    :if (($res->"status") = "finished") do={
        :local data [:deserialize from=json ($res->"data")]
        :if (($data->"ok") = true) do={
            :foreach upd in=($data->"result") do={
                :local updId [:tonum ($upd->"update_id")]
                :if ($updId > $lastUpdateId) do={ :set lastUpdateId $updId }

                :local msg ($upd->"message")
                :if ([:typeof $msg] = "array") do={
                    :local chatId [:tostr ($msg->"chat"->"id")]
                    :if ($chatId = $adminChatId) do={
                        :local text ""
                        :if ([:typeof ($msg->"web_app_data")] = "array") do={
                            :set text [:tostr ($msg->"web_app_data"->"data")]
                        } else={
                            :if ([:typeof ($msg->"text")] = "str") do={
                                :set text [:tostr ($msg->"text")]
                            }
                        }

                        :if ([:len $text] > 0) do={
                            :local safeChars "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.~"

                            # 1. إضافة مستخدم جديد (/add_user|user|pass|prof|gb|comment)
                            :if ([:find $text "/add_user|"] = 0) do={
                                :local p1 [:find $text "|" 0]
                                :local p2 [:find $text "|" ($p1 + 1)]
                                :local p3 [:find $text "|" ($p2 + 1)]
                                :local p4 [:find $text "|" ($p3 + 1)]
                                :local p5 [:find $text "|" ($p4 + 1)]

                                :local uName [:pick $text ($p1 + 1) $p2]
                                :local uPass [:pick $text ($p2 + 1) $p3]
                                :local uProf [:pick $text ($p3 + 1) $p4]
                                :local uGb [:tonum [:pick $text ($p4 + 1) $p5]]
                                :local uComm [:pick $text ($p5 + 1) [:len $text]]
                                :local limBytes ($uGb * 1073741824)

                                /ip hotspot user add name=$uName password=$uPass profile=$uProf limit-bytes-total=$limBytes comment=$uComm server="out"

                                :local encUser ""
                                :for i from=0 to=([:len $uName] - 1) do={
                                    :local ch [:pick $uName $i ($i + 1)]
                                    :if ([:typeof [:find $safeChars $ch]] = "num") do={ :set encUser ($encUser . $ch) } else={
                                        :if ($ch = " ") do={ :set encUser ($encUser . "%20") } else={ :set encUser ($encUser . "_") }
                                    }
                                }
                                :local encProf ""
                                :for i from=0 to=([:len $uProf] - 1) do={
                                    :local ch [:pick $uProf $i ($i + 1)]
                                    :if ($ch = "+") do={ :set encProf ($encProf . "%2B") } else={
                                        :if ($ch = "/") do={ :set encProf ($encProf . "%2F") } else={
                                            :if ($ch = " ") do={ :set encProf ($encProf . "%20") } else={ :set encProf ($encProf . $ch) }
                                        }
                                    }
                                }

                                :local okMsg ("%E2%9C%85%20%3Cb%3E%D8%AA%D9%85%20%D8%A5%D9%86%D8%B4%D8%A7%D8%A1%20%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%20%D8%A8%D9%86%D8%AC%D8%A7%D8%AD%3C%2Fb%3E%0A%0A%F0%9F%91%A4%20%3Cb%3E%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%3A%3C%2Fb%3E%20%3Ccode%3E" . $encUser . "%3C%2Fcode%3E%0A%F0%9F%9A%80%20%3Cb%3E%D8%A7%D9%84%D8%A8%D8%B1%D9%88%D9%81%D8%A7%D9%8A%D9%84%3A%3C%2Fb%3E%20%3Ccode%3E" . $encProf . "%3C%2Fcode%3E%0A%F0%9F%93%A6%20%3Cb%3E%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%3A%3C%2Fb%3E%20%3Ccode%3E" . $uGb . "%20GB%3C%2Fcode%3E")
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=HTML&text=" . $okMsg) keep-result=no
                                /system script run Sync_Users_GitHub
                            }

                            # 2. تجديد باقة أو تعديل بروفايل (/renew_user|target|prof|gb|comment)
                            :if ([:find $text "/renew_user|"] = 0) do={
                                :local p1 [:find $text "|" 0]
                                :local p2 [:find $text "|" ($p1 + 1)]
                                :local p3 [:find $text "|" ($p2 + 1)]
                                :local p4 [:find $text "|" ($p3 + 1)]

                                :local target [:pick $text ($p1 + 1) $p2]
                                :local uProf [:pick $text ($p2 + 1) $p3]
                                :local uGb [:tonum [:pick $text ($p3 + 1) $p4]]
                                :local uComm [:pick $text ($p4 + 1) [:len $text]]

                                :local uid [/ip hotspot user find name=$target]
                                :if ([:len $uid] = 0) do={
                                    :foreach x in=[/ip hotspot user find] do={
                                        :if ([:tostr $x] = $target) do={ :set uid $x }
                                    }
                                }

                                :if ([:len $uid] > 0) do={
                                    :local realName [/ip hotspot user get $uid name]
                                    :local isAscii true
                                    :for i from=0 to=([:len $realName] - 1) do={
                                        :local ch [:pick $realName $i ($i + 1)]
                                        :if (([:typeof [:find $safeChars $ch]] != "num") && ($ch != " ")) do={
                                            :set isAscii false
                                        }
                                    }

                                    :local dispUser $realName
                                    :if (($isAscii = false) || ([:find $realName "Arabic_User_"] = 0)) do={
                                        :local extracted ""
                                        :local toPos [:find $uComm " To "]
                                        :if ([:typeof $toPos] = "num") do={
                                            :set extracted [:pick $uComm 0 $toPos]
                                        } else={
                                            :local devPos [:find $uComm " (Dev:"]
                                            :if ([:typeof $devPos] = "num") do={
                                                :set extracted [:pick $uComm 0 $devPos]
                                            } else={
                                                :set extracted $uComm
                                            }
                                        }

                                        :local cleanExt ""
                                        :for i from=0 to=([:len $extracted] - 1) do={
                                            :local ch [:pick $extracted $i ($i + 1)]
                                            :if (([:typeof [:find $safeChars $ch]] = "num") || ($ch = " ")) do={
                                                :set cleanExt ($cleanExt . $ch)
                                            }
                                        }
                                        :if ([:len $cleanExt] > 1) do={
                                            :set dispUser $cleanExt
                                        } else={
                                            :set dispUser "Arabic User"
                                        }
                                    }

                                    :local encUser ""
                                    :for i from=0 to=([:len $dispUser] - 1) do={
                                        :local ch [:pick $dispUser $i ($i + 1)]
                                        :if ([:typeof [:find $safeChars $ch]] = "num") do={ :set encUser ($encUser . $ch) } else={
                                            :if ($ch = " ") do={ :set encUser ($encUser . "%20") } else={ :set encUser ($encUser . "_") }
                                        }
                                    }

                                    :local encProf ""
                                    :for i from=0 to=([:len $uProf] - 1) do={
                                        :local ch [:pick $uProf $i ($i + 1)]
                                        :if ($ch = "+") do={ :set encProf ($encProf . "%2B") } else={
                                            :if ($ch = "/") do={ :set encProf ($encProf . "%2F") } else={
                                                :if ($ch = " ") do={ :set encProf ($encProf . "%20") } else={ :set encProf ($encProf . $ch) }
                                            }
                                        }
                                    }

                                    :local encComm ""
                                    :for i from=0 to=([:len $uComm] - 1) do={
                                        :local ch [:pick $uComm $i ($i + 1)]
                                        :if ([:typeof [:find $safeChars $ch]] = "num") do={
                                            :set encComm ($encComm . $ch)
                                        } else={
                                            :if ($ch = " ") do={ :set encComm ($encComm . "%20") } else={
                                                :if ($ch = ":") do={ :set encComm ($encComm . "%3A") } else={
                                                    :if ($ch = "(") do={ :set encComm ($encComm . "%28") } else={
                                                        :if ($ch = ")") do={ :set encComm ($encComm . "%29") } else={
                                                            :if ($ch = "[") do={ :set encComm ($encComm . "%5B") } else={
                                                                :if ($ch = "]") do={ :set encComm ($encComm . "%5D") } else={
                                                                    :if ($ch = "+") do={ :set encComm ($encComm . "%2B") } else={
                                                                        :if ($ch = "/") do={ :set encComm ($encComm . "%2F") } else={
                                                                            :set encComm ($encComm . "%20")
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    :local renMsg ""
                                    :if ($uGb = 0) do={
                                        /ip hotspot user set $uid profile=$uProf comment=$uComm disabled=no
                                        /ip hotspot active remove [find user=$realName]
                                        :set renMsg ("%E2%9C%85%20%3Cb%3E%D8%AA%D9%85%20%D8%A7%D9%84%D8%AA%D8%B9%D8%AF%D9%8A%D9%84%20(%D8%A8%D8%AF%D9%88%D9%86%20%D8%AA%D8%B5%D9%81%D9%8A%D8%B1)%3C%2Fb%3E%0A%0A%F0%9F%91%A4%20%3Cb%3E%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%3A%3C%2Fb%3E%20%3Ccode%3E" . $encUser . "%3C%2Fcode%3E%0A%F0%9F%9A%80%20%3Cb%3E%D8%A7%D9%84%D8%A8%D8%B1%D9%88%D9%81%D8%A7%D9%8A%D9%84%3A%3C%2Fb%3E%20%3Ccode%3E" . $encProf . "%3C%2Fcode%3E%0A%F0%9F%92%AC%20%3Cb%3E%D8%A7%D9%84%D9%83%D9%88%D9%85%D9%86%D8%AA%3A%3C%2Fb%3E%0A%3Ccode%3E" . $encComm . "%3C%2Fcode%3E")
                                    } else={
                                        :local limBytes ($uGb * 1073741824)
                                        /ip hotspot user reset-counters $uid
                                        /ip hotspot user set $uid profile=$uProf limit-bytes-total=$limBytes comment=$uComm disabled=no
                                        /ip hotspot active remove [find user=$realName]
                                        :set renMsg ("%F0%9F%94%84%20%3Cb%3E%D8%AA%D9%85%20%D8%AA%D8%AC%D8%AF%D9%8A%D8%AF%20%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%20%D8%A8%D9%86%D8%AC%D8%A7%D8%AD%3C%2Fb%3E%0A%0A%F0%9F%91%A4%20%3Cb%3E%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%3A%3C%2Fb%3E%20%3Ccode%3E" . $encUser . "%3C%2Fcode%3E%0A%F0%9F%9A%80%20%3Cb%3E%D8%A7%D9%84%D8%A8%D8%B1%D9%88%D9%81%D8%A7%D9%8A%D9%84%3A%3C%2Fb%3E%20%3Ccode%3E" . $encProf . "%3C%2Fcode%3E%0A%F0%9F%93%A6%20%3Cb%3E%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%3A%3C%2Fb%3E%20%3Ccode%3E" . $uGb . "%20GB%3C%2Fcode%3E%0A%F0%9F%92%AC%20%3Cb%3E%D8%A7%D9%84%D9%83%D9%88%D9%85%D9%86%D8%AA%3A%3C%2Fb%3E%0A%3Ccode%3E" . $encComm . "%3C%2Fcode%3E")
                                    }

                                    /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=HTML&text=" . $renMsg) keep-result=no
                                    /system script run Sync_Users_GitHub
                                } else={
                                    /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=%E2%9D%8C%20%D9%84%D9%85%20%D9%8A%D8%AA%D9%85%20%D8%A7%D9%84%D8%B9%D8%AB%D9%88%D8%B1%20%D8%B9%D9%84%D9%89%20%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83") keep-result=no
                                }
                            }

                            # 3. حالة السيرفر (/status)
                            :if ([:find $text "/status"] = 0) do={
                                :local cpu [/system resource get cpu-load]
                                :local freeMem ([/system resource get free-memory] / 1048576)
                                :local up [/system resource get uptime]
                                :local stMsg ("%F0%9F%96%A5%EF%B8%8F%20%D8%AD%D8%A7%D9%84%D8%A9%20%D8%A7%D9%84%D8%B3%D9%8A%D8%B1%D9%81%D8%B1%20(hAP%20ax2)%3A%0A%E2%9A%99%EF%B8%8F%20%D8%A7%D9%84%D9%85%D8%B9%D8%A7%D9%84%D8%AC%3A%20" . $cpu . "%25%0A%F0%9F%92%BE%20%D8%A7%D9%84%D8%B1%D8%A7%D9%85%20%D8%A7%D9%84%D9%85%D8%AA%D8%A7%D8%AD%3A%20" . $freeMem . "%20MB%0A%E2%8F%B1%EF%B8%8F%20%D9%85%D8%AF%D8%A9%20%D8%A7%D9%84%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%3A%20" . $up)
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $stMsg) keep-result=no
                            }

                            # 4. استهلاك الخط (/traffic)
                            :if ([:find $text "/traffic"] = 0) do={
                                :local rxGB ([/interface get [find name="in1"] rx-byte] / 1073741824)
                                :local txGB ([/interface get [find name="in1"] tx-byte] / 1073741824)
                                :local trMsg ("%F0%9F%93%8A%20%D8%A7%D8%B3%D8%AA%D9%87%D9%84%D8%A7%D9%83%20%D8%AE%D8%B7%20%D8%A7%D9%84%D8%A5%D9%86%D8%AA%D8%B1%D9%86%D8%AA%20(in1)%3A%0A%E2%AC%87%EF%B8%8F%20%D8%A7%D9%84%D8%AA%D8%AD%D9%85%D9%8A%D9%84%3A%20" . $rxGB . "%20GB%0A%E2%AC%86%EF%B8%8F%20%D8%A7%D9%84%D8%B1%D9%81%D8%B9%3A%20" . $txGB . "%20GB")
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $trMsg) keep-result=no
                            }

                            # 5. السرعة الحالية (/speed)
                            :if ([:find $text "/speed"] = 0) do={
                                :local mon [/interface monitor-traffic [find name="in1"] once as-value]
                                :local rxMbps (($mon->"rx-bits-per-second") / 1000000)
                                :local txMbps (($mon->"tx-bits-per-second") / 1000000)
                                :local spMsg ("%E2%9A%A1%20%D8%A7%D9%84%D8%B3%D8%B1%D8%B9%D8%A9%20%D8%A7%D9%84%D8%AD%D8%A7%D9%84%D9%8A%D8%A9%20(in1)%3A%0A%E2%AC%87%EF%B8%8F%20Download%3A%20" . $rxMbps . "%20Mbps%0A%E2%AC%86%EF%B8%8F%20Upload%3A%20" . $txMbps . "%20Mbps")
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $spMsg) keep-result=no
                            }

                            # 6. فحص البنج (/ping) - 5 نبضات Google بتنسيق Time = ms كبير وواضح
                            :if ([:find $text "/ping"] = 0) do={
                                :local targetHost "www.google.com"
                                :local gIp ""
                                :do { :set gIp [:tostr [:resolve $targetHost]] } on-error={}

                                :if ([:len $gIp] = 0) do={
                                    :local failDns ("%E2%9D%8C%20%3Cb%3E%D9%81%D8%B4%D9%84%20%D8%A7%D9%84%D8%A7%D8%AA%D8%B5%D8%A7%D9%84%20%D8%A8%D9%80%20Google%3C%2Fb%3E%0A%D8%AA%D8%A3%D9%83%D8%AF%20%D9%85%D9%86%20%D8%A7%D9%84%D8%A5%D9%86%D8%AA%D8%B1%D9%86%D8%AA")
                                    /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=HTML&text=" . $failDns) keep-result=no
                                } else={
                                    :local pRes [/ping $gIp count=5 as-value]
                                    :local rcv 0
                                    :local sumMs 0
                                    :local linesStr ""

                                    :foreach r in=$pRes do={
                                        :local tVal ($r->"time")
                                        :if ([:typeof $tVal] != "nothing") do={
                                            :set rcv ($rcv + 1)
                                            :local tStr [:tostr $tVal]
                                            :local msNum 0
                                            :local colonPos [:find $tStr ":"]
                                            :if ([:typeof $colonPos] = "num") do={
                                                :local dotPos [:find $tStr "."]
                                                :local secPart [:tonum [:pick $tStr ($colonPos + 1) $dotPos]]
                                                :local subPart [:pick $tStr ($dotPos + 1) [:len $tStr]]
                                                :while ([:len $subPart] < 3) do={ :set subPart ($subPart . "0") }
                                                :local msPart [:tonum [:pick $subPart 0 3]]
                                                :set msNum (($secPart * 1000) + $msPart)
                                            } else={
                                                :set msNum [:tonum $tStr]
                                            }
                                            :if ($msNum = 0) do={ :set msNum 1 }
                                            :set sumMs ($sumMs + $msNum)

                                            :set linesStr ($linesStr . "%E2%9A%A1%20%3Cb%3ETime%20%3D%20" . $msNum . "%20ms%3C%2Fb%3E%0A")
                                        } else={
                                            :set linesStr ($linesStr . "%E2%9D%8C%20%3Cb%3ETime%20%3D%20Timeout%3C%2Fb%3E%0A")
                                        }
                                    }

                                    :local avgMs 0
                                    :if ($rcv > 0) do={ :set avgMs ($sumMs / $rcv) }

                                    :local pgMsg ("%F0%9F%8F%93%20%3Cb%3E%D9%81%D8%AD%D8%B5%20%D8%A7%D9%84%D8%A8%D9%86%D8%AC%20(Google)%3A%3C%2Fb%3E%0A%0A" . $linesStr . "%0A%F0%9F%93%8A%20%3Cb%3E%D9%88%D8%B5%D9%84%3A%3C%2Fb%3E%20" . $rcv . "%2F5%20%7C%20%3Cb%3E%D8%A7%D9%84%D9%85%D8%AA%D9%88%D8%B3%D8%B7%3A%3C%2Fb%3E%20" . $avgMs . "%20ms")
                                    /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=HTML&text=" . $pgMsg) keep-result=no
                                }
                            }

                            # 7. الوقت والتاريخ (/clock)
                            :if ([:find $text "/clock"] = 0) do={
                                :local cTime [/system clock get time]
                                :local cDate [/system clock get date]
                                :local clMsg ("%F0%9F%95%92%20%D8%A7%D9%84%D9%88%D9%82%D8%AA%3A%20" . $cTime . "%0A%F0%9F%93%85%20%D8%A7%D9%84%D8%AA%D8%A7%D8%B1%D9%8A%D8%AE%3A%20" . $cDate)
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $clMsg) keep-result=no
                            }

                            # 8. إعادة تشغيل الراوتر (/reboot)
                            :if ([:find $text "/reboot"] = 0) do={
                                :set botBusy false
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=%F0%9F%94%84%20%D8%AC%D8%A7%D8%B1%D9%8A%20%D8%A5%D8%B9%D8%A7%D8%AF%D8%A9%20%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%20%D8%A7%D9%84%D8%B1%D8%A7%D9%88%D8%AA%D8%B1...") keep-result=no
                                :delay 2s
                                /system reboot
                            }

                            # 9. الأجهزة المجاورة (/neighbors) - مرتبة وبدون تكرار
                            :if ([:find $text "/neighbors"] = 0) do={
                                :local keys [:toarray ""]
                                :local lines [:toarray ""]
                                :local seen [:toarray ""]
                                :local allowedNb "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:"
                                :foreach n in=[/ip neighbor find] do={
                                    :local id [/ip neighbor get $n identity]
                                    :local adr [:tostr [/ip neighbor get $n address]]
                                    :local mac [:tostr [/ip neighbor get $n mac-address]]
                                    :local iface [:tostr [/ip neighbor get $n interface]]

                                    :local dispAddr ""
                                    :if ([:len $adr] > 0) do={
                                        :set dispAddr $adr
                                    } else={
                                        :if ([:len $mac] > 0) do={
                                            :set dispAddr $mac
                                        } else={
                                            :set dispAddr ("No-MAC-" . $iface)
                                        }
                                    }

                                    :local isDup false
                                    :foreach s in=$seen do={
                                        :if ($s = $dispAddr) do={ :set isDup true }
                                    }

                                    :if ($isDup = false) do={
                                        :set seen ($seen , $dispAddr)

                                        :local cleanId ""
                                        :for i from=0 to=([:len $id] - 1) do={
                                            :local ch [:pick $id $i ($i + 1)]
                                            :if ([:typeof [:find $allowedNb $ch]] = "num") do={
                                                :set cleanId ($cleanId . $ch)
                                            } else={
                                                :set cleanId ($cleanId . "%20")
                                            }
                                        }
                                        :if ([:len $cleanId] = 0) do={ :set cleanId ("Port:" . $iface) }

                                        :local sortKey 999999
                                        :if ([:len $adr] > 0) do={
                                            :local d1 [:find $adr "."]
                                            :local rem1 [:pick $adr ($d1 + 1) [:len $adr]]
                                            :local d2 [:find $rem1 "."]
                                            :local rem2 [:pick $rem1 ($d2 + 1) [:len $rem1]]
                                            :local d3 [:find $rem2 "."]
                                            :local o3 [:tonum [:pick $rem2 0 $d3]]
                                            :local o4 [:tonum [:pick $rem2 ($d3 + 1) [:len $rem2]]]
                                            :set sortKey (($o3 * 1000) + $o4)
                                        }

                                        :local paddedIp $dispAddr
                                        :while ([:len $paddedIp] < 17) do={
                                            :set paddedIp ($paddedIp . "%20")
                                        }

                                        :local line ("%E2%96%AA%20%60" . $paddedIp . "%60%20%7C%20" . $cleanId)
                                        :set keys ($keys , $sortKey)
                                        :set lines ($lines , $line)
                                    }
                                }

                                :local count [:len $keys]
                                :if ($count > 1) do={
                                    :for i from=0 to=($count - 2) do={
                                        :for j from=0 to=($count - 2 - $i) do={
                                            :if (($keys->$j) > ($keys->($j + 1))) do={
                                                :local tmpK ($keys->$j)
                                                :set ($keys->$j) ($keys->($j + 1))
                                                :set ($keys->($j + 1)) $tmpK

                                                :local tmpL ($lines->$j)
                                                :set ($lines->$j) ($lines->($j + 1))
                                                :set ($lines->($j + 1)) $tmpL
                                            }
                                        }
                                    }
                                }

                                :local nbMsg "%F0%9F%93%A1%20%D8%A7%D9%84%D8%A3%D8%AC%D9%87%D8%B2%D8%A9%20%D8%A7%D9%84%D9%85%D8%AC%D8%A7%D9%88%D8%B1%D8%A9%20(%D9%85%D8%B1%D8%AA%D8%A8%D8%A9)%3A%0A"
                                :if ($count = 0) do={
                                    :set nbMsg ($nbMsg . "%D9%84%D8%A7%20%D8%AA%D9%88%D8%AC%D8%AF%20%D8%A3%D8%AC%D9%87%D8%B2%D8%A9%20%D9%85%D8%AC%D8%A7%D9%88%D8%B1%D8%A9%20%D8%AD%D8%A7%D9%84%D9%8A%D8%A7%D9%8B")
                                } else={
                                    :foreach item in=$lines do={
                                        :set nbMsg ($nbMsg . $item . "%0A")
                                    }
                                }
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=Markdown&text=" . $nbMsg) keep-result=no
                            }

                        }
                    }
                }
            }
        }
    }
} on-error={}

:set botBusy false
