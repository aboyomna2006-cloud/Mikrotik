# ==========================================
# Telegram_Receiver Script (RouterOS v7)
# Full Control + Clean Two-Line Active Users
# ==========================================

:global tgReceiverRunning
:if ($tgReceiverRunning = true) do={ :error "Already running" }
:set tgReceiverRunning true

:do {
    :local botToken "9010171304:AAGo8QbUxcWaC6Y4wWb2i8Wb0M6YvJHLYZM"
    :local adminChatId "486915427"
    :global lastUpdateId

    :if ([:typeof $lastUpdateId] = "nothing") do={ :set lastUpdateId 0 }

    :local url ("https://api.telegram.org/bot" . $botToken . "/getUpdates?offset=" . ($lastUpdateId + 1) . "&timeout=1")
    :local result [/tool fetch url=$url as-value output=user]
    :local content ($result->"data")

    :if ([:len $content] > 30) do={
        :local data [:deserialize from=json $content]
        :local updates ($data->"result")

        :foreach update in=$updates do={
            :local updateId ($update->"update_id")
            :if ($updateId > $lastUpdateId) do={
                :set lastUpdateId $updateId

                :local msg ($update->"message")
                :local chatId [:tostr ($msg->"chat"->"id")]

                :if ($chatId = $adminChatId) do={
                    :local text ""
                    :if ([:typeof ($msg->"web_app_data")] != "nothing") do={
                        :set text ($msg->"web_app_data"->"data")
                    } else={
                        :set text ($msg->"text")
                    }

                    :if ([:len $text] > 0) do={

                        # 1. إضافة مستخدم جديد
                        :if ([:find $text "/add_user|"] = 0) do={
                            :local raw [:pick $text 10 [:len $text]]
                            :local p1 [:find $raw "|"]
                            :local uName [:pick $raw 0 $p1]
                            :local rem1 [:pick $raw ($p1 + 1) [:len $raw]]
                            :local p2 [:find $rem1 "|"]
                            :local uPass [:pick $rem1 0 $p2]
                            :local rem2 [:pick $rem1 ($p2 + 1) [:len $rem1]]
                            :local p3 [:find $rem2 "|"]
                            :local uProf [:pick $rem2 0 $p3]
                            :local rem3 [:pick $rem2 ($p3 + 1) [:len $rem2]]
                            :local p4 [:find $rem3 "|"]
                            :local uGb [:pick $rem3 0 $p4]
                            :local uComment [:pick $rem3 ($p4 + 1) [:len $rem3]]
                            :local limitBytes ([:tonum $uGb] * 1073741824)

                            :if ([:len [/ip hotspot user find name=$uName]] > 0) do={
                                :local errMsg "%E2%9D%8C%20%D8%A7%D8%B3%D9%85%20%D8%A7%D9%84%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85%20%D9%85%D9%88%D8%AC%D9%88%D8%AF%20%D8%A8%D8%A7%D9%84%D9%81%D8%B9%D9%84!"
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $errMsg) keep-result=no
                            } else={
                                /ip hotspot user add name=$uName password=$uPass profile=$uProf server=out limit-bytes-total=$limitBytes comment=$uComment

                                :local encUser ""
                                :for i from=0 to=([:len $uName] - 1) do={
                                    :local ch [:pick $uName $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encUser ($encUser . "%20") } else={ :set encUser ($encUser . $ch) }
                                }
                                :local encPass ""
                                :for i from=0 to=([:len $uPass] - 1) do={
                                    :local ch [:pick $uPass $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encPass ($encPass . "%20") } else={ :set encPass ($encPass . $ch) }
                                }
                                :local encComm ""
                                :for i from=0 to=([:len $uComment] - 1) do={
                                    :local ch [:pick $uComment $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encComm ($encComm . "%20") } else={ :set encComm ($encComm . $ch) }
                                }
                                :local encProf $uProf
                                :if ($uProf = "512+") do={ :set encProf "512%2B" }

                                :local confMsg ("%E2%9C%85%20%D8%AA%D9%85%20%D8%A5%D9%86%D8%B4%D8%A7%D8%A1%20%D8%A7%D9%84%D9%83%D8%A7%D8%B1%D8%AA%20%D8%A8%D9%86%D8%AC%D8%A7%D8%AD%21%0A%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%0A%F0%9F%91%A4%20%D8%A7%D9%84%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85%3A%20" . $encUser . "%0A%F0%9F%94%91%20%D8%A7%D9%84%D8%A8%D8%A7%D8%B3%D9%88%D8%B1%D8%AF%3A%20" . $encPass . "%0A%F0%9F%9A%80%20%D8%A7%D9%84%D8%A8%D8%B1%D9%88%D9%81%D8%A7%D9%8A%D9%84%3A%20" . $encProf . "%0A%F0%9F%93%A6%20%D8%A7%D9%84%D8%B1%D8%B5%D9%8A%D8%AF%3A%20" . $uGb . "%20GB%0A%F0%9F%92%AC%20%D8%A7%D9%84%D9%83%D9%88%D9%85%D9%86%D8%AA%3A%20" . $encComm)
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $confMsg) keep-result=no

                                :local waMsg ("%D8%B1%D8%B3%D8%A7%D9%84%D8%A9%20%D8%A7%D9%84%D9%88%D8%A7%D8%AA%D8%B3%D8%A7%D8%A8%20%D9%84%D9%84%D8%B9%D9%85%D9%8A%D9%84%3A%0A%0A%D9%85%D8%B1%D8%AD%D8%A8%D8%A7%D9%8B%20%D8%A8%D9%83%20%D9%81%D9%8A%20%D8%B4%D8%A8%D9%83%D8%AA%D9%86%D8%A7%20%F0%9F%8C%90%0A%D8%A8%D9%8A%D8%A7%D9%86%D8%A7%D8%AA%20%D8%A7%D9%84%D8%AF%D8%AE%D9%88%D9%84%20%D8%A7%D9%84%D8%AE%D8%A7%D8%B5%D8%A9%20%D8%A8%D9%83%3A%0A%D8%A7%D9%84%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85%3A%20" . $encUser . "%0A%D8%A7%D9%84%D8%B1%D9%85%D8%B2%3A%20" . $encPass . "%0A%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%3A%20" . $uGb . "%20%D8%AC%D9%8A%D8%AC%D8%A7")
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $waMsg) keep-result=no

                                :do { /system script run Sync_Users_GitHub } on-error={}
                            }
                        }

                        # 2. تجديد باقة مشترك
                        :if ([:find $text "/renew_user|"] = 0) do={
                            :local raw [:pick $text 12 [:len $text]]
                            :local p1 [:find $raw "|"]
                            :local rQuery [:pick $raw 0 $p1]
                            :local rem1 [:pick $raw ($p1 + 1) [:len $raw]]
                            :local p2 [:find $rem1 "|"]
                            :local rProf [:pick $rem1 0 $p2]
                            :local rem2 [:pick $rem1 ($p2 + 1) [:len $rem1]]
                            :local p3 [:find $rem2 "|"]
                            :local rGb [:pick $rem2 0 $p3]
                            :local rManualComm [:pick $rem2 ($p3 + 1) [:len $rem2]]

                            :local matchedIds [:toarray ""]
                            :if ([:pick $rQuery 0 1] = "*") do={
                                :foreach uid in=[/ip hotspot user find] do={
                                    :if ([:tostr $uid] = $rQuery) do={
                                        :set matchedIds ($matchedIds , $uid)
                                    }
                                }
                            }

                            :if ([:len $matchedIds] = 0) do={
                                :set matchedIds [/ip hotspot user find name=$rQuery]
                            }

                            :if ([:len $matchedIds] = 0) do={
                                :foreach uid in=[/ip hotspot user find] do={
                                    :local c [/ip hotspot user get $uid comment]
                                    :if ([:typeof [:find $c $rQuery]] = "num") do={
                                        :set matchedIds ($matchedIds , $uid)
                                    }
                                }
                            }

                            :if ([:len $matchedIds] = 0) do={
                                :local notFoundMsg "%E2%9D%8C%20%D9%84%D9%85%20%D9%8A%D8%AA%D9%85%20%D8%A7%D9%84%D8%B9%D8%AB%D9%88%D8%B1%20%D8%B9%D9%84%D9%89%20%D8%A3%D9%8A%20%D9%85%D8%B4%D8%AA%D8%B1%D9%83%20%D9%85%D8%B7%D8%A7%D8%A8%D9%82%21"
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $notFoundMsg) keep-result=no
                            }

                            :if ([:len $matchedIds] > 1) do={
                                :local multiMsg "%E2%9A%A0%EF%B8%8F%20%D9%8A%D9%88%D8%AC%D8%AF%20%D8%A3%D9%83%D8%AB%D8%B1%20%D9%85%D9%86%20%D9%85%D8%B4%D8%AA%D8%B1%D9%83%20%D8%A8%D9%87%D8%B0%D8%A7%20%D8%A7%D9%84%D8%A7%D8%B3%D9%85%D8%8C%20%D8%A7%D9%83%D8%AA%D8%A8%20%D8%A7%D9%84%D9%8A%D9%88%D8%B2%D8%B1%20%D8%A8%D8%A7%D9%84%D8%AA%D8%AD%D8%AF%D9%8A%D8%AF%3A%0A%0A"
                                :foreach mid in=$matchedIds do={
                                    :local mUser [/ip hotspot user get $mid name]
                                    :local mComm [/ip hotspot user get $mid comment]
                                    :local encMU ""
                                    :for i from=0 to=([:len $mUser] - 1) do={
                                        :local ch [:pick $mUser $i ($i + 1)]
                                        :if ($ch = " ") do={ :set encMU ($encMU . "%20") } else={ :set encMU ($encMU . $ch) }
                                    }
                                    :local encMC ""
                                    :for i from=0 to=([:len $mComm] - 1) do={
                                        :local ch [:pick $mComm $i ($i + 1)]
                                        :if ($ch = " ") do={ :set encMC ($encMC . "%20") } else={ :set encMC ($encMC . $ch) }
                                    }
                                    :set multiMsg ($multiMsg . "%F0%9F%91%A4%20" . $encMU . "%0A%F0%9F%92%AC%20" . $encMC . "%0A%E2%94%80%E2%94%80%E2%94%80%E2%94%80%E2%94%80%E2%94%80%0A")
                                }
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $multiMsg) keep-result=no
                            }

                            :if ([:len $matchedIds] = 1) do={
                                :local uId ($matchedIds->0)
                                :local rUser [/ip hotspot user get $uId name]
                                :local rPass [/ip hotspot user get $uId password]
                                :local oldComm [/ip hotspot user get $uId comment]
                                :local limitBytes ([:tonum $rGb] * 1073741824)
                                :local finalComm ""
                                :local newDateStr ""

                                :if ([:len $rManualComm] > 0) do={
                                    :set finalComm $rManualComm
                                    :local toPosM [:find $rManualComm " To "]
                                    :if ([:typeof $toPosM] = "num") do={
                                        :set newDateStr [:pick $rManualComm ($toPosM + 4) [:len $rManualComm]]
                                    } else={
                                        :set newDateStr $rManualComm
                                    }
                                } else={
                                    :local baseName $rUser
                                    :local d 0
                                    :local m 0
                                    :local y 0
                                    :local hasOldDate false

                                    :local toPos [:find $oldComm " To "]
                                    :if ([:typeof $toPos] = "num") do={
                                        :set baseName [:pick $oldComm 0 $toPos]
                                        :local afterTo [:pick $oldComm ($toPos + 4) [:len $oldComm]]
                                        :local spPos [:find $afterTo " "]
                                        :local dateToken $afterTo
                                        :if ([:typeof $spPos] = "num") do={
                                            :set dateToken [:pick $afterTo 0 $spPos]
                                        }
                                        :local dash1 [:find $dateToken "-"]
                                        :if ([:typeof $dash1] = "num") do={
                                            :set d [:tonum [:pick $dateToken 0 $dash1]]
                                            :local remD [:pick $dateToken ($dash1 + 1) [:len $dateToken]]
                                            :local dash2 [:find $remD "-"]
                                            :if ([:typeof $dash2] = "num") do={
                                                :set m [:tonum [:pick $remD 0 $dash2]]
                                                :set y [:tonum [:pick $remD ($dash2 + 1) [:len $remD]]]
                                                :if ($d > 0 && $m > 0 && $y > 2000) do={ :set hasOldDate true }
                                            }
                                        }
                                    } else={
                                        :if ([:len $oldComm] > 0) do={ :set baseName $oldComm }
                                    }

                                    :if ($hasOldDate = false) do={
                                        :local sysDate [/system clock get date]
                                        :set y [:tonum [:pick $sysDate 0 4]]
                                        :set m [:tonum [:pick $sysDate 5 7]]
                                        :set d [:tonum [:pick $sysDate 8 10]]
                                    }

                                    :local daysToAdd 30
                                    :while ($daysToAdd > 0) do={
                                        :local maxDays 31
                                        :if ($m = 4 || $m = 6 || $m = 9 || $m = 11) do={ :set maxDays 30 }
                                        :if ($m = 2) do={
                                            :if (($y % 4) = 0) do={ :set maxDays 29 } else={ :set maxDays 28 }
                                        }
                                        :set d ($d + 1)
                                        :if ($d > $maxDays) do={
                                            :set d 1
                                            :set m ($m + 1)
                                            :if ($m > 12) do={
                                                :set m 1
                                                :set y ($y + 1)
                                            }
                                        }
                                        :set daysToAdd ($daysToAdd - 1)
                                    }

                                    :local dStr [:tostr $d]
                                    :local mStr [:tostr $m]
                                    :set newDateStr ($dStr . "-" . $mStr . "-" . [:tostr $y])
                                    :set finalComm ($baseName . " To " . $newDateStr)
                                }

                                /ip hotspot user set $uId profile=$rProf limit-bytes-total=$limitBytes comment=$finalComm disabled=no
                                /ip hotspot user reset-counters $uId

                                :local displayUser $rUser
                                :if ([:pick $rQuery 0 1] = "*") do={
                                    :set displayUser $finalComm
                                }
                                :local encRUser ""
                                :for i from=0 to=([:len $displayUser] - 1) do={
                                    :local ch [:pick $displayUser $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encRUser ($encRUser . "%20") } else={ :set encRUser ($encRUser . $ch) }
                                }
                                :local encRPass ""
                                :for i from=0 to=([:len $rPass] - 1) do={
                                    :local ch [:pick $rPass $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encRPass ($encRPass . "%20") } else={ :set encRPass ($encRPass . $ch) }
                                }
                                :local encRComm ""
                                :for i from=0 to=([:len $finalComm] - 1) do={
                                    :local ch [:pick $finalComm $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encRComm ($encRComm . "%20") } else={ :set encRComm ($encRComm . $ch) }
                                }
                                :local encRDate ""
                                :for i from=0 to=([:len $newDateStr] - 1) do={
                                    :local ch [:pick $newDateStr $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encRDate ($encRDate . "%20") } else={ :set encRDate ($encRDate . $ch) }
                                }
                                :local encRProf $rProf
                                :if ($rProf = "512+") do={ :set encRProf "512%2B" }

                                :local renMsg ("%E2%9C%A8%20%D8%AA%D9%85%20%D8%AA%D9%86%D9%81%D9%8A%D8%B0%20%D8%A7%D9%84%D8%AA%D8%AC%D8%AF%D9%8A%D8%AF%20%D8%A8%D9%86%D8%AC%D8%A7%D8%AD%20%E2%9C%85%0A%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%E2%94%81%0A%F0%9F%91%A4%20%D8%A7%D9%84%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85%3A%20" . $encRUser . "%0A%F0%9F%94%91%20%D8%A7%D9%84%D8%A8%D8%A7%D8%B3%D9%88%D8%B1%D8%AF%3A%20" . $encRPass . "%0A%F0%9F%9A%80%20%D8%A7%D9%84%D8%A8%D8%B1%D9%88%D9%81%D8%A7%D9%8A%D9%84%3A%20" . $encRProf . "%0A%F0%9F%93%A6%20%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%20%D8%A7%D9%84%D8%AC%D8%AF%D9%8A%D8%AF%D8%A9%3A%20" . $rGb . "%20GB%0A%F0%9F%94%84%20%D8%A7%D9%84%D8%A7%D8%B3%D8%AA%D9%87%D9%84%D8%A7%D9%83%3A%200%20MB%20(%D8%AA%D9%85%20%D8%A7%D9%84%D8%AA%D8%B5%D9%81%D9%8A%D8%B1)%0A%F0%9F%93%85%20%D8%AA%D8%A7%D8%B1%D9%8A%D8%AE%20%D8%A7%D9%84%D8%A7%D9%86%D8%AA%D9%87%D8%A7%D8%A1%3A%20" . $encRDate . "%0A%F0%9F%92%AC%20%D8%A7%D9%84%D9%83%D9%88%D9%85%D9%86%D8%AA%20%D8%A7%D9%84%D8%AC%D8%AF%D9%8A%D8%AF%3A%20" . $encRComm)
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $renMsg) keep-result=no

                                :local waRenMsg ("%D8%B1%D8%B3%D8%A7%D9%84%D8%A9%20%D8%A7%D9%84%D9%88%D8%A7%D8%AA%D8%B3%D8%A7%D8%A8%20%D9%84%D9%84%D8%B9%D9%85%D9%8A%D9%84%3A%0A%0A%D8%AA%D9%85%20%D8%AA%D8%AC%D8%AF%D9%8A%D8%AF%20%D8%A7%D8%B4%D8%AA%D8%B1%D8%A7%D9%83%D9%83%20%D8%A8%D9%86%D8%AC%D8%A7%D8%AD%20%E2%9C%85%0A%D8%A7%D9%84%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85%3A%20" . $encRUser . "%0A%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%20%D8%A7%D9%84%D8%AC%D8%AF%D9%8A%D8%AF%D8%A9%3A%20" . $rGb . "%20%D8%AC%D9%8A%D8%AC%D8%A7%0A%D8%B5%D8%A7%D9%84%D8%AD%D8%A9%20%D8%AD%D8%AA%D9%89%3A%20" . $encRDate)
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $waRenMsg) keep-result=no

                                :do { /system script run Sync_Users_GitHub } on-error={}
                            }
                        }

                        # 3. المشتركين النشطين (/users) - بطاقة سطرين مريحة للعين: الاسم كامل فوق، والـ IP + الاستهلاك موزونين تحته
                        :if ([:find $text "/users"] = 0) do={
                            :local uList [:toarray ""]
                            :local allowedChr "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:"
                            :foreach i in=[/ip hotspot active find] do={
                                :local uName [/ip hotspot active get $i user]
                                :local ip [:tostr [/ip hotspot active get $i address]]
                                :local bIn [/ip hotspot active get $i bytes-in]
                                :local bOut [/ip hotspot active get $i bytes-out]
                                :local totMB (($bIn + $bOut) / 1048576)

                                :local sessRaw ""
                                :if ($totMB >= 1024) do={
                                    :local gInt ($totMB / 1024)
                                    :local gDec ((($totMB % 1024) * 10) / 1024)
                                    :set sessRaw ([:tostr $gInt] . "." . [:tostr $gDec] . "%20GB")
                                } else={
                                    :set sessRaw ([:tostr $totMB] . "%20MB")
                                }

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
                                    :if ([:typeof [:find $allowedChr $ch]] = "num") do={
                                        :set cleanName ($cleanName . $ch)
                                    } else={
                                        :if ($ch = " ") do={ :set cleanName ($cleanName . "%20") }
                                    }
                                }
                                :if ([:len $cleanName] = 0) do={ :set cleanName "User" }

                                :local sortKey 0
                                :if ([:len $ip] > 0) do={
                                    :local d1 [:find $ip "."]
                                    :local rem1 [:pick $ip ($d1 + 1) [:len $ip]]
                                    :local d2 [:find $rem1 "."]
                                    :local rem2 [:pick $rem1 ($d2 + 1) [:len $rem1]]
                                    :local d3 [:find $rem2 "."]
                                    :local o3 [:tonum [:pick $rem2 0 $d3]]
                                    :local o4 [:tonum [:pick $rem2 ($d3 + 1) [:len $rem2]]]
                                    :set sortKey (($o3 * 1000) + $o4)
                                }

                                :local paddedIp $ip
                                :while ([:len $paddedIp] < 12) do={
                                    :set paddedIp ($paddedIp . "%20")
                                }

                                :local line ("%E2%96%AA%20*" . $cleanName . "*%0A%20%20%E2%94%94%20%60" . $paddedIp . "%60%20%7C%20%60" . $sessRaw . "%60")
                                :set uList ($uList , ({{ "k"=$sortKey; "t"=$line }}))
                            }

                            :local count [:len $uList]
                            :if ($count > 1) do={
                                :for i from=0 to=($count - 2) do={
                                    :for j from=0 to=($count - 2 - $i) do={
                                        :local a ($uList->$j)
                                        :local b ($uList->($j + 1))
                                        :if (($a->"k") > ($b->"k")) do={
                                            :set ($uList->$j) $b
                                            :set ($uList->($j + 1)) $a
                                        }
                                    }
                                }
                            }

                            :local outMsg ("%F0%9F%91%A5%20%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%D9%8A%D9%86%20%D8%A7%D9%84%D9%86%D8%B4%D8%B7%D9%8A%D9%86%20(" . $count . ")%3A%0A%0A")
                            :if ($count = 0) do={
                                :set outMsg ($outMsg . "%D9%84%D8%A7%20%D9%8A%D9%88%D8%AC%D8%AF%20%D9%85%D8%B4%D8%AA%D8%B1%D9%83%D9%8A%D9%86%20%D9%86%D8%B4%D8%B7%D9%8A%D9%86%20%D8%AD%D8%A7%D9%84%D9%8A%D8%A7%D9%8B")
                            } else={
                                :foreach item in=$uList do={
                                    :set outMsg ($outMsg . ($item->"t") . "%0A")
                                }
                            }
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=Markdown&text=" . $outMsg) keep-result=no
                        }

                        # 4. استهلاك الخط (/traffic)
                        :if ([:find $text "/traffic"] = 0) do={
                            :local rxBytes [/interface get in1 rx-byte]
                            :local txBytes [/interface get in1 tx-byte]
                            :local rxGB ($rxBytes / 1073741824)
                            :local txGB ($txBytes / 1073741824)
                            :local trMsg ("%F0%9F%93%8A%20%D8%A7%D8%B3%D8%AA%D9%87%D9%84%D8%A7%D9%83%20%D8%AE%D8%B7%20%D8%A7%D9%84%D8%A5%D9%86%D8%AA%D8%B1%D9%86%D8%AA%20(in1)%3A%0A%E2%AC%87%20%D8%A7%D9%84%D8%AA%D8%AD%D9%85%D9%8A%D9%84%3A%20" . $rxGB . "%20GB%0A%E2%AC%86%20%D8%A7%D9%84%D8%B1%D9%81%D8%B9%3A%20" . $txGB . "%20GB")
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $trMsg) keep-result=no
                        }

                        # 5. حالة السيرفر (/status)
                        :if ([:find $text "/status"] = 0) do={
                            :local cpu [/system resource get cpu-load]
                            :local freeMem ([/system resource get free-memory] / 1048576)
                            :local uptime [/system resource get uptime]
                            :local stMsg ("%F0%9F%96%A5%20%D8%AD%D8%A7%D9%84%D8%A9%20%D8%A7%D9%84%D8%B3%D9%8A%D8%B1%D9%81%D8%B1%20(hAP%20ax2)%3A%0A%E2%9A%99%20%D8%A7%D9%84%D9%85%D8%B9%D8%A7%D9%84%D8%AC%3A%20" . $cpu . "%25%0A%F0%9F%92%BE%20%D8%A7%D9%84%D8%B1%D8%A7%D9%85%20%D8%A7%D9%84%D9%85%D8%AA%D8%A7%D8%AD%3A%20" . $freeMem . "%20MB%0A%E2%8F%B1%20%D9%85%D8%AF%D8%A9%20%D8%A7%D9%84%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%3A%20" . $uptime)
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $stMsg) keep-result=no
                        }

                        # 6. فحص البنج (/ping)
                        :if ([:find $text "/ping"] = 0) do={
                            :local pCount [/ping 8.8.8.8 count=4]
                            :local pMsg ("%F0%9F%8F%93%20%D9%86%D8%AA%D9%8A%D8%AC%D8%A9%20%D8%A7%D9%84%D8%A8%D9%86%D8%AC%20%D8%B9%D9%84%D9%89%208.8.8.8%3A%20" . $pCount . "%2F4%20%D9%86%D8%A7%D8%AC%D8%AD")
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $pMsg) keep-result=no
                        }

                        # 7. السرعة الحالية (/speed)
                        :if ([:find $text "/speed"] = 0 && [:find $text "/speed_test"] != 0) do={
                            :local mon [/interface monitor-traffic in1 once as-value]
                            :local rxBps ($mon->"rx-bits-per-second")
                            :local txBps ($mon->"tx-bits-per-second")

                            :local rxKbps ($rxBps / 1000)
                            :local txKbps ($txBps / 1000)

                            :local rxInt ($rxBps / 1000000)
                            :local rxRem (($rxBps % 1000000) / 10000)
                            :local rxDec [:tostr $rxRem]
                            :if ($rxRem < 10) do={ :set rxDec ("0" . $rxDec) }
                            :local rxRaw ([:tostr $rxInt] . "." . $rxDec . " Mbps")
                            :local rxStr ([:tostr $rxInt] . "." . $rxDec . "%20Mbps")
                            :local pad1 (11 - [:len $rxRaw])
                            :while ($pad1 > 0) do={ :set rxStr ($rxStr . "%20"); :set pad1 ($pad1 - 1) }

                            :local txInt ($txBps / 1000000)
                            :local txRem (($txBps % 1000000) / 10000)
                            :local txDec [:tostr $txRem]
                            :if ($txRem < 10) do={ :set txDec ("0" . $txDec) }
                            :local txRaw ([:tostr $txInt] . "." . $txDec . " Mbps")
                            :local txStr ([:tostr $txInt] . "." . $txDec . "%20Mbps")
                            :local pad2 (11 - [:len $txRaw])
                            :while ($pad2 > 0) do={ :set txStr ($txStr . "%20"); :set pad2 ($pad2 - 1) }

                            :local spMsg ("%E2%9A%A1%20%D8%A7%D9%84%D8%B3%D8%AD%D8%A8%20%D8%A7%D9%84%D8%AD%D8%A7%D9%84%D9%8A%20%D8%B9%D9%84%D9%89%20%D8%A7%D9%84%D8%AE%D8%B7%20(in1)%3A%0A")
                            :set spMsg ($spMsg . "%E2%AC%87%20%60" . $rxStr . "%60%20%7C%20%60" . $rxKbps . "%20Kbps%60%0A")
                            :set spMsg ($spMsg . "%E2%AC%86%20%60" . $txStr . "%60%20%7C%20%60" . $txKbps . "%20Kbps%60")
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=Markdown&text=" . $spMsg) keep-result=no
                        }

                        # 8. الوقت والتاريخ (/clock)
                        :if ([:find $text "/clock"] = 0) do={
                            :local d [/system clock get date]
                            :local t [/system clock get time]
                            :local cMsg ("%F0%9F%95%92%20%D8%A7%D9%84%D8%AA%D8%A7%D8%B1%D9%8A%D8%AE%3A%20" . $d . "%0A%E2%8F%B0%20%D8%A7%D9%84%D9%88%D9%82%D8%AA%3A%20" . $t)
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $cMsg) keep-result=no
                        }

                        # 9. الأجهزة المجاورة (/neighbors)
                        :if ([:find $text "/neighbors"] = 0) do={
                            :local nbList [:toarray ""]
                            :local allowedNb "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_:"
                            :foreach n in=[/ip neighbor find] do={
                                :local id [/ip neighbor get $n identity]
                                :local adr [:tostr [/ip neighbor get $n address]]
                                :local cleanId ""
                                :for i from=0 to=([:len $id] - 1) do={
                                    :local ch [:pick $id $i ($i + 1)]
                                    :if ([:typeof [:find $allowedNb $ch]] = "num") do={
                                        :set cleanId ($cleanId . $ch)
                                    } else={
                                        :set cleanId ($cleanId . "%20")
                                    }
                                }
                                :local sortKey 0
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
                                    :set adr "No-IP"
                                    :set sortKey 999999
                                }

                                :local paddedIp $adr
                                :while ([:len $paddedIp] < 15) do={
                                    :set paddedIp ($paddedIp . "%20")
                                }

                                :local line ("%E2%96%AA%20%60" . $paddedIp . "%60%20%7C%20" . $cleanId)
                                :set nbList ($nbList , ({{ "k"=$sortKey; "t"=$line }}))
                            }

                            :local count [:len $nbList]
                            :if ($count > 1) do={
                                :for i from=0 to=($count - 2) do={
                                    :for j from=0 to=($count - 2 - $i) do={
                                        :local a ($nbList->$j)
                                        :local b ($nbList->($j + 1))
                                        :if (($a->"k") > ($b->"k")) do={
                                            :set ($nbList->$j) $b
                                            :set ($nbList->($j + 1)) $a
                                        }
                                    }
                                }
                            }

                            :local nbMsg "%F0%9F%93%A1%20%D8%A7%D9%84%D8%A3%D8%AC%D9%87%D8%B2%D8%A9%20%D8%A7%D9%84%D9%85%D8%AC%D8%A7%D9%88%D8%B1%D8%A9%20(%D9%85%D8%B1%D8%AA%D8%A8%D8%A9)%3A%0A"
                            :if ($count = 0) do={
                                :set nbMsg ($nbMsg . "%D9%84%D8%A7%20%D8%AA%D9%88%D8%AC%D8%AF%20%D8%A3%D8%AC%D9%87%D8%B2%D8%A9%20%D9%85%D8%AC%D8%A7%D9%88%D8%B1%D8%A9%20%D8%AD%D8%A7%D9%84%D9%8A%D8%A7%D9%8B")
                            } else={
                                :foreach item in=$nbList do={
                                    :set nbMsg ($nbMsg . ($item->"t") . "%0A")
                                }
                            }
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&parse_mode=Markdown&text=" . $nbMsg) keep-result=no
                        }

                        # 10. استعلام عن مشترك (/find_user & /info)
                        :if ([:find $text "/find_user"] = 0) do={
                            :local helpFind "%F0%9F%94%8D%20%D9%84%D9%84%D8%A8%D8%AD%D8%AB%20%D8%B9%D9%86%20%D9%85%D8%B4%D8%AA%D8%B1%D9%83%20%D8%A7%D9%83%D8%AA%D8%A8%3A%0A%2Finfo%20%D8%A7%D8%B3%D9%85_%D8%A7%D9%84%D9%85%D8%B3%D8%AA%D8%AE%D8%AF%D9%85"
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $helpFind) keep-result=no
                        }

                        :if ([:find $text "/info "] = 0) do={
                            :local targetUser [:pick $text 6 [:len $text]]
                            :local uId [/ip hotspot user find name=$targetUser]
                            :if ([:len $uId] > 0) do={
                                :local prof [/ip hotspot user get $uId profile]
                                :local comm [/ip hotspot user get $uId comment]
                                :local lim ([/ip hotspot user get $uId limit-bytes-total] / 1073741824)
                                :local used (([/ip hotspot user get $uId bytes-in] + [/ip hotspot user get $uId bytes-out]) / 1048576)
                                :local encTgtUser ""
                                :for i from=0 to=([:len $targetUser] - 1) do={
                                    :local ch [:pick $targetUser $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encTgtUser ($encTgtUser . "%20") } else={ :set encTgtUser ($encTgtUser . $ch) }
                                }
                                :local encInfoComm ""
                                :for i from=0 to=([:len $comm] - 1) do={
                                    :local ch [:pick $comm $i ($i + 1)]
                                    :if ($ch = " ") do={ :set encInfoComm ($encInfoComm . "%20") } else={ :set encInfoComm ($encInfoComm . $ch) }
                                }
                                :local encInfoProf $prof
                                :if ($prof = "512+") do={ :set encInfoProf "512%2B" }
                                :local infMsg ("%F0%9F%93%8B%20%D8%A8%D9%8A%D8%A7%D9%86%D8%A7%D8%AA%20%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%3A%20" . $encTgtUser . "%0A%F0%9F%92%AC%20%D8%A7%D9%84%D9%83%D9%88%D9%85%D9%86%D8%AA%3A%20" . $encInfoComm . "%0A%F0%9F%9A%80%20%D8%A7%D9%84%D8%A8%D8%B1%D9%88%D9%81%D8%A7%D9%8A%D9%84%3A%20" . $encInfoProf . "%0A%F0%9F%93%A6%20%D8%A7%D9%84%D8%A8%D8%A7%D9%82%D8%A9%3A%20" . $lim . "%20GB%0A%F0%9F%93%89%20%D8%A7%D9%84%D8%A7%D8%B3%D8%AA%D9%87%D9%84%D8%A7%D9%83%3A%20" . $used . "%20MB")
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=" . $infMsg) keep-result=no
                            } else={
                                /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=%E2%9D%8C%20%D8%A7%D9%84%D9%85%D8%B4%D8%AA%D8%B1%D9%83%20%D8%BA%D9%8A%D8%B1%20%D9%85%D9%88%D8%AC%D9%88%D8%AF") keep-result=no
                            }
                        }

                        # 11. إعادة تشغيل الراوتر (/reboot)
                        :if ([:find $text "/reboot"] = 0) do={
                            /tool fetch url=("https://api.telegram.org/bot" . $botToken . "/sendMessage?chat_id=" . $adminChatId . "&text=%F0%9F%94%84%20%D8%AC%D8%A7%D8%B1%D9%8A%20%D8%A5%D8%B9%D8%A7%D8%AF%D8%A9%20%D8%AA%D8%B4%D8%BA%D9%8A%D9%84%20%D8%A7%D9%84%D8%B1%D8%A7%D9%88%D8%AA%D8%B1...") keep-result=no
                            /system reboot
                        }
                    }
                }
            }
        }
    }
} on-error={}

:set tgReceiverRunning false
