Sequence (what to do when)
1.	Infra apply (Terraform / GitHub Actions)
	Creates: RG, VNet/Subnet, App Service Plan, Linux Web App (public disabled), Private Endpoint, and privatelink.azurewebsites.net private DNS zone + VNet link.
	Result: your PE gets a private IP (e.g., 10.20.1.7).

2.	Public DNS ownership TXT (can be done any time after the app exists)
	In the public zone for contoso.com, add the TXT: asuid.app.internal.contoso.com with the value from App Service → Custom domains → “Get TXT record”.
	This is required so the hostname binding won’t fail later.

3.	Internal DNS for your custom internal name (after PE exists)
	Azure Private DNS option: create private zone internal.contoso.com, link it to your VNet, then add A record:
app → <PE private IP>
	AD DNS/on-prem DNS option: in the internal.contoso.com zone, add A record app → <PE private IP>.
	This step must wait until the PE IP is known (after infra create).


4.	Add the custom hostname + bind your PFX
	az webapp config hostname add … --hostname app.internal.contoso.com
	az webapp config ssl upload … and … ssl bind … --ssl-type SNI
	These will succeed once the public TXT exists; traffic will work once internal A exists.


5.	Test from inside the VNet
	nslookup app.internal.contoso.com → should return the PE IP.
	curl -vk https://app.internal.contoso.com → should present your uploaded cert.


Day 1 setup
git add README.md
git config --global user.email "sid1985@gmail.com"
git config --global user.name "Sid Bhatt"
git commit -m "first commit"
git branch -M main
git push -u origin main
