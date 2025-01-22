import React from 'react';
import Typography, { TypographyProps } from '@mui/material/Typography';

type FooterProps = Omit<TypographyProps, 'variant' | 'color' | 'align'>;

export default function Footer({ children, ...props }: FooterProps) {
  return (
    <Typography
      variant="body2"
      color="text.secondary"
      align="center"
      {...props}
    >
      {children}
    </Typography>
  );
}
