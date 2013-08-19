#ifdef MELTER_DEPTH

//Note: Uses CustomFX 0

BuildFX() {
	move body to y-axis MELTER_DEPTH now;
	while ((get BUILD_PERCENT_LEFT)>99) {
		sleep 30;
	}
	while(get BUILD_PERCENT_LEFT) {
		emit-sfx 1024 from base;
		move body to y-axis (MELTER_DEPTH / 100 * (get BUILD_PERCENT_LEFT)) now;
		sleep 100;
	}
	move body to y-axis 0 now;
}

#endif
