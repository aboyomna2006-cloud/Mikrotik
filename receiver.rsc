# ==========================================
# Telegram_Receiver (RouterOS v7)
# Full Bot Handler + WebApp + Keep-Usage Mode
# ==========================================

:local botToken "9010171304:AAGo8QbUxcWaC6Y4wWb2i8Wb0M6YvJHLYZM"
:local adminChatId "486915427"

:global lastUpdateId
:if ([:typeof $lastUpdateId] != "num") do={ :set lastUpdateId 0 }

:local apiUrl ("https://api.telegram.org/bot" . $botToken . "/getUpdates?offset=" . ($lastUpdateId + 1) . "&timeout=5")
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
                            /system script run Sync_Users_GitHub

                            :local okMsg ("%E2%9C%85%20%D8%AA%D9%85%20%D8%A5%D9%86%D8%B4%D8%A7%D8%A1%20%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%20%D8%A8%D9%86%D8%AC%D8%A7%D8%AD%3A%0A%F0%9F%91%A4%20%60" . $uName . "%60%0A%F0%9F%9A%80%20" . $uProf . "%20%7C%20%F0%9F%93%A6%20" . $uGb . "%20GB")
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=Markdown&text=" . $okMsg) keep-result=no
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
                                :local renMsg ""

                                :if ($uGb = 0) do={
                                    /ip hotspot user set $uid profile=$uProf comment=$uComm disabled=no
                                    /ip hotspot active remove [find user=$realName]
                                    :set renMsg ("%E2%9C%85%20%D8%AA%D9%85%20%D8%AA%D8%B9%D8%AF%D9%8A%D9%84%20%D8%A7%D9%84%D8%A8%D8%B1%D9%88%D9%81%D8%A7%D9%8A%D9%84%20%D9%88%D8%A7%D9%84%D9%83%D9%88%D9%85%D9%86%D8%AA%20(%D8%A8%D8%AF%D9%88%D9%86%20%D8%AA%D8%B5%D9%81%D9%8A%D8%B1)%3A%0A%F0%9F%91%A4%20%60" . $realName . "%60%0A%F0%9F%9A%80%20" . $uProf)
                                } else={
                                    :local limBytes ($uGb * 1073741824)
                                    /ip hotspot user reset-counters $uid
                                    /ip hotspot user set $uid profile=$uProf limit-bytes-total=$limBytes comment=$uComm disabled=no
                                    /ip hotspot active remove [find user=$realName]
                                    :set renMsg ("%F0%9F%94%84%20%D8%AA%D9%85%20%D8%AA%D8%AC%D8%AF%D9%8A%D8%AF%20%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%20%D8%A8%D9%86%D8%AC%D8%A7%D8%AD%3A%0A%F0%9F%91%A4%20%60" . $realName . "%60%0A%F0%9F%9A%80%20" . $uProf . "%20%7C%20%F0%9F%93%A6%20" . $uGb . "%20GB")
                                }

                                /system script run Sync_Users_GitHub
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=Markdown&text=" . $renMsg) keep-result=no
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

                        # 6. فحص البنج (/ping)
                        :if ([:find $text "/ping"] = 0) do={
                            :local pRes [/ping 8.8.8.8 count=3 as-value]
                            :local sent [:len $pRes]
                            :local rcv 0
                            :foreach r in=$pRes do={
                                :if ([:typeof ($r->"time")] != "nothing") do={ :set rcv ($rcv + 1) }
                            }
                            :local pgMsg ("%F0%9F%8F%93%20%D9%81%D8%AD%D8%B5%20%D8%A7%D9%84%D8%A8%D9%86%D8%AC%20(8.8.8.8)%3A%0A%D9%88%D8%B5%D9%84%20" . $rcv . "%20%D9%85%D9%86%20" . $sent)
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $pgMsg) keep-result=no
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
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=%F0%9F%94%84%20%D8%AC%D8%A7%D8%B1%D9%8A%20%D8%A5%D8%B9%D8%A7%D8%AF%D8%A9%20%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%20%D8%A7%D9%84%D8%B1%D8%A7%D9%88%D8%AA%D8%B1...") keep-result=no
                            :delay 2s
                            /system reboot
                        }

                        # 9. الأجهزة المجاورة (/neighbors) - يجيب MAC + Interface لو مفيش IP
                        :if ([:find $text "/neighbors"] = 0) do={
                            :local keys [:toarray ""]
                            :local lines [:toarray ""]
                            :local allowedNb "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:"
                            :foreach n in=[/ip neighbor find] do={
                                :local id [/ip neighbor get $n identity]
                                :local adr [:tostr [/ip neighbor get $n address]]
                                :local mac [:tostr [/ip neighbor get $n mac-address]]
                                :local iface [:tostr [/ip neighbor get $n interface]]

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

                                :local sortKey 0
                                :local dispAddr $adr
                                :if ([:len $adr] > 0) do={
                                    :local d1 [:find $adr "."]
                                    :local rem1 [:pick $adr ($d1 + 1) [:len $adr]]
                                    :local d2 [:find $rem1 "."]
                                    :local rem2 [:pick $rem1 ($d2 + 1) [:len $rem1]]
                                    :local d3 [:find $rem2 "."]
                                    :local o3 [:tonum [:pick $rem2 0 $d3]]
                                    :local o4 [:tonum [:pick $rem2 ($d3 + 1) [:len $rem2]]]
                                    :set sortKey (($o3 * 1000) + $o4)
                                } else={
                                    :if ([:len $mac] > 0) do={
                                        :set dispAddr $mac
                                    } else={
                                        :set dispAddr "No-MAC"
                                    }
                                    :set sortKey 999999
                                }

                                :local paddedIp $dispAddr
                                :while ([:len $paddedIp] < 17) do={
                                    :set paddedIp ($paddedIp . "%20")
                                }

                                :local line ("%E2%96%AA%20%60" . $paddedIp . "%60%20%7C%20" . $cleanId)
                                :set keys ($keys , $sortKey)
                                :set lines ($lines , $line)
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
