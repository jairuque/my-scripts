#!/bin/bash

echo "=== UFW Optimization Guide ==="
echo ""
echo "To check your current UFW configuration, run:"
echo "sudo ufw status verbose"
echo ""

echo "Basic UFW optimization steps:"
echo "1. Enable logging (helps monitor traffic):"
echo "   sudo ufw logging on"
echo ""

echo "2. Set default policies (DENY incoming, ALLOW outgoing):"
echo "   sudo ufw default deny incoming"
echo "   sudo ufw default allow outgoing"
echo ""

echo "3. Allow essential services:"
echo "   sudo ufw allow ssh"  # Or specify port: sudo ufw allow 22/tcp
echo "   sudo ufw allow http" # Port 80
echo "   sudo ufw allow https" # Port 443
echo ""

echo "4. For a desktop system, you might also want:"
echo "   sudo ufw allow 53"    # DNS
echo "   sudo ufw allow proto udp from any to any port 67:68" # DHCP
echo ""

echo "5. To enable UFW:"
echo "   sudo ufw enable"
echo ""

echo "6. Additional security rules you might consider:"
echo "   # Rate limiting SSH connections"
echo "   sudo ufw limit ssh/tcp"
echo ""
echo "   # Block suspicious IPs (replace with actual malicious IPs)"
echo "   sudo ufw deny from <malicious-ip>"
echo ""

echo "7. To check status after changes:"
echo "   sudo ufw status numbered"
echo ""

echo "8. To remove a rule (if needed):"
echo "   sudo ufw status numbered  # Find the rule number"
echo "   sudo ufw delete <rule-number>"
echo ""

echo ""
echo "Security Best Practices:"
echo "- Always allow SSH before enabling UFW (if accessing remotely)"
echo "- Regularly review active rules"
echo "- Monitor logs: sudo ufw show raw"
echo "- Keep system updated"
echo "- Consider fail2ban for additional protection"
echo ""

echo "Example of a secure basic setup:"
echo "# Set defaults"
echo "sudo ufw default deny incoming"
echo "sudo ufw default allow outgoing"
echo ""
echo "# Allow essential services"
echo "sudo ufw allow ssh"
echo "sudo ufw allow http"
echo "sudo ufw allow https"
echo ""
echo "# Enable firewall"
echo "sudo ufw enable"
echo ""