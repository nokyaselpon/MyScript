#!/bin/bash
ram1=$(free -h | grep -i mem | awk {'print $2'})
ram2=$(free -h | grep -i mem | awk {'print $4'})
ram3=$(free -h | grep -i mem | awk {'print $3'})
uso=$(top -bn1 | awk '/Cpu/ { cpu = "" 100 - $8 "%" }; END { print cpu }')
system=$(cat /etc/MEUIPADM)

[[ ! -d /etc/SSHPlus ]] && mkdir /etc/SSHPlus > /dev/null 2>&1
link_bin="https://raw.githubusercontent.com/AAAAAEXQOSyIpN2JZ0ehUQ/ADM-ULTIMATE-NEW-FREE/master/Herramientas/proxy.py"
[[ ! -e /etc/SSHPlus/proxy.py ]] && wget -O /etc/SSHPlus/proxy.py ${link_bin} > /dev/null 2>&1 && chmod +x /etc/SSHPlus/proxy.py

fun_socks () {
	clear
    echo -e "\E[44;1;37m            GERENCIAR PROXY SOCKS             \E[0m"
    echo ""
    [[ $(netstat -nplt |grep 'python' | wc -l) != '0' ]] && {
        sks='\033[1;32mON'
        var_sks1="DESATIVAR SOCKS"
        echo -e "\033[1;33mPORTAS\033[1;37m: \033[1;32m$(netstat -nplt |grep 'python' | awk {'print $4'} |cut -d: -f2 |xargs)"
    } || {
        var_sks1="ATIVAR SOCKS"
        sks='\033[1;31mOFF'
    }
    echo ""
	echo -e "\033[1;31m[\033[1;36m1\033[1;31m] \033[1;37m• \033[1;33m$var_sks1\033[0m"
	echo -e "\033[1;31m[\033[1;36m2\033[1;31m] \033[1;37m• \033[1;33mABRIR PORTA\033[0m"
	echo -e "\033[1;31m[\033[1;36m3\033[1;31m] \033[1;37m• \033[1;33mALTERAR STATUS\033[0m"
	echo -e "\033[1;31m[\033[1;36m0\033[1;31m] \033[1;37m• \033[1;33mVOLTAR\033[0m"
	echo ""
	echo -ne "\033[1;32mOQUE DESEJA FAZER \033[1;33m?\033[1;37m "; read resposta
	if [[ "$resposta" = '1' ]]; then
		if ps x | grep proxy.py|grep -v grep 1>/dev/null 2>/dev/null; then
			clear
			echo -e "\E[41;1;37m             PROXY SOCKS              \E[0m"
			echo ""
			fun_socksoff () {
				for pidproxy in  `screen -ls | grep ".proxy" | awk {'print $1'}`; do
					screen -r -S "$pidproxy" -X quit
				done
				[[ $(grep -wc "proxy.py" /etc/autostart) != '0' ]] && {
		    		sed -i '/proxy.py/d' /etc/autostart
		    	}
				sleep 1
				screen -wipe > /dev/null
			}
			echo -e "\033[1;32mDESATIVANDO O PROXY SOCKS\033[1;33m"
			echo ""
			fun_bar 'fun_socksoff'
			echo ""
			echo -e "\033[1;32mPROXY SOCKS DESATIVADO COM SUCESSO!\033[1;33m"
			sleep 3
			fun_socks
		else
			clear
			echo -e "\E[44;1;37m             PROXY SOCKS              \E[0m"
		    echo ""
		    echo -ne "\033[1;32mQUAL PORTA DESEJA ULTILIZAR \033[1;33m?\033[1;37m: "; read porta
		    if [[ -z "$porta" ]]; then
		    	echo ""
		    	echo -e "\033[1;31mPorta invalida!"
		    	sleep 3
		    	clear
		    	fun_conexao
		    fi
		    verif_ptrs $porta
		    fun_inisocks () {
		    	sleep 1
		    	screen -dmS proxy python /etc/SSHPlus/proxy.py $porta
		    	[[ $(grep -wc "proxy.py" /etc/autostart) = '0' ]] && {
		    		echo -e "netstat -tlpn | grep python > /dev/null && echo 'ON' || screen -dmS proxy python /etc/SSHPlus/proxy.py $porta" >> /etc/autostart
		    	} || {
		            sed -i '/proxy.py/d' /etc/autostart
		            echo -e "netstat -tlpn | grep python > /dev/null && echo 'ON' || screen -dmS proxy python /etc/SSHPlus/proxy.py $porta" >> /etc/autostart
		        }
		    }
		    echo ""
		    echo -e "\033[1;32mINICIANDO O PROXY SOCKS\033[1;33m"
		    echo ""
		    fun_bar 'fun_inisocks'
		    echo ""
		    echo -e "\033[1;32mPROXY SOCKS ATIVADO COM SUCESSO\033[1;33m"
		    sleep 3
		    fun_socks
		fi
	elif [[ "$resposta" = '2' ]]; then
		if ps x | grep proxy.py|grep -v grep 1>/dev/null 2>/dev/null; then
			sockspt=$(netstat -nplt |grep 'python' | awk {'print $4'} |cut -d: -f2 |xargs)
			clear
			echo -e "\E[44;1;37m            PROXY SOCKS             \E[0m"
			echo ""
			echo -e "\033[1;33mPORTAS EM USO: \033[1;32m$sockspt"
			echo ""
			echo -ne "\033[1;32mQUAL PORTA DESEJA ULTILIZAR \033[1;33m?\033[1;37m: "; read porta
			if [[ -z "$porta" ]]; then
				echo ""
				echo -e "\033[1;31mPorta invalida!"
				sleep 3
				clear
				fun_conexao
			fi
			verif_ptrs $porta
			echo ""
			echo -e "\033[1;32mINICIANDO O PROXY SOCKS NA PORTA \033[1;31m$porta\033[1;33m"
			echo ""
			abrirptsks () {
				sleep 1
				screen -dmS proxy python /etc/SSHPlus/proxy.py $porta
				sleep 1
			}
			fun_bar 'abrirptsks'
			echo ""
			echo -e "\033[1;32mPROXY SOCKS ATIVADO COM SUCESSO\033[1;33m"
			sleep 3
			fun_socks
		else
			clear
			echo -e "\033[1;31mFUNCAO INDISPONIVEL\n\n\033[1;33mATIVE O SOCKS PRIMEIRO !\033[1;33m"
			sleep 2
			fun_socks
		fi
	elif [[ "$resposta" = '3' ]]; then
		if ps x | grep proxy.py|grep -v grep 1>/dev/null 2>/dev/null; then
			clear
			msgsocks=$(cat /etc/SSHPlus/proxy.py |grep -E "MSG =" | awk -F = '{print $2}' |cut -d "'" -f 2)
			echo -e "\E[44;1;37m             PROXY SOCKS              \E[0m"
			echo ""
			echo -e "\033[1;33mSTATUS: \033[1;32m$msgsocks"
			echo""
			echo -ne "\033[1;32mINFORME SEU STATUS\033[1;31m:\033[1;37m "; read msgg
			if [[ -z "$msgg" ]]; then
				echo ""
				echo -e "\033[1;31mStatus invalido!"
				sleep 3
				fun_conexao
			fi
			echo -e "\n\033[1;31m[\033[1;36m01\033[1;31m]\033[1;33m AZUL"
			echo -e "\033[1;31m[\033[1;36m02\033[1;31m]\033[1;33m VERDE"
			echo -e "\033[1;31m[\033[1;36m03\033[1;31m]\033[1;33m VERMELHO"
			echo -e "\033[1;31m[\033[1;36m04\033[1;31m]\033[1;33m AMARELO"
			echo -e "\033[1;31m[\033[1;36m05\033[1;31m]\033[1;33m ROSA"
			echo -e "\033[1;31m[\033[1;36m06\033[1;31m]\033[1;33m CYANO"
			echo -e "\033[1;31m[\033[1;36m07\033[1;31m]\033[1;33m LARANJA"
			echo -e "\033[1;31m[\033[1;36m08\033[1;31m]\033[1;33m ROXO"
			echo -e "\033[1;31m[\033[1;36m09\033[1;31m]\033[1;33m PRETO"
			echo -e "\033[1;31m[\033[1;36m10\033[1;31m]\033[1;33m SEM COR"
			echo ""
			echo -ne "\033[1;32mQUAL A COR\033[1;31m ?\033[1;37m : "; read sts_cor
			if [[ "$sts_cor" = "1" ]] || [[ "$sts_cor" = "01" ]]; then
				cor_sts='blue'
			elif [[ "$sts_cor" = "2" ]] || [[ "$sts_cor" = "02" ]]; then
				cor_sts='green'
			elif [[ "$sts_cor" = "3" ]] || [[ "$sts_cor" = "03" ]]; then
				cor_sts='red'
			elif [[ "$sts_cor" = "4" ]] || [[ "$sts_cor" = "04" ]]; then
				cor_sts='yellow'
			elif [[ "$sts_cor" = "5" ]] || [[ "$sts_cor" = "05" ]]; then
				cor_sts='#F535AA'
			elif [[ "$sts_cor" = "6" ]] || [[ "$sts_cor" = "06" ]]; then
				cor_sts='cyan'
			elif [[ "$sts_cor" = "7" ]] || [[ "$sts_cor" = "07" ]]; then
				cor_sts='#FF7F00'
			elif [[ "$sts_cor" = "8" ]] || [[ "$sts_cor" = "08" ]]; then
				cor_sts='#9932CD'
			elif [[ "$sts_cor" = "9" ]] || [[ "$sts_cor" = "09" ]]; then
				cor_sts='black'
			elif [[ "$sts_cor" = "10" ]]; then
				cor_sts='null'
			else
				echo -e "\n\033[1;33mOPCAO INVALIDA !"
				cor_sts='null'
			fi
			fun_msgsocks () {
				msgsocks2=$(cat /etc/SSHPlus/proxy.py |grep "MSG =" | awk -F = '{print $2}')
				sed -i "s/$msgsocks2/ '$msgg'/g" /etc/SSHPlus/proxy.py
				sleep 1
				cor_old=$(grep 'color=' /etc/SSHPlus/proxy.py | cut -d '"' -f2)
				sed -i "s/$cor_old/$cor_sts/g" /etc/SSHPlus/proxy.py

			}
			echo ""
			echo -e "\033[1;32mALTERANDO STATUS!"
			echo ""
			fun_bar 'fun_msgsocks'
			restartsocks () {
				if ps x | grep proxy.py|grep -v grep 1>/dev/null 2>/dev/null; then
				    echo -e "$(netstat -nplt |grep 'python' | awk {'print $4'} |cut -d: -f2 |xargs)" > /tmp/Pt_sks
					for pidproxy in  `screen -ls | grep ".proxy" | awk {'print $1'}`; do
						screen -r -S "$pidproxy" -X quit
					done
					screen -wipe > /dev/null
					_Ptsks="$(cat /tmp/Pt_sks)"
					sleep 1
					screen -dmS proxy python /etc/SSHPlus/proxy.py $_Ptsks
					rm /tmp/Pt_sks
				fi
			}
			echo ""
			echo -e "\033[1;32mREINICIANDO PROXY SOCKS!"
			echo ""
			fun_bar 'restartsocks'
			echo ""
			echo -e "\033[1;32mSTATUS ALTERADO COM SUCESSO!"
			sleep 3
			fun_socks
		else
			clear
			echo -e "\033[1;31mFUNCAO INDISPONIVEL\n\n\033[1;33mATIVE O SOCKS PRIMEIRO !\033[1;33m"
			sleep 2
			fun_socks
		fi
	elif [[ "$resposta" = '0' ]]; then
		echo ""
		echo -e "\033[1;31mRetornando...\033[0m"
		sleep 2
		fun_conexao
	else
		echo ""
		echo -e "\033[1;31mOpcao invalida !\033[0m"
		sleep 2
		fun_socks
	fi

}
