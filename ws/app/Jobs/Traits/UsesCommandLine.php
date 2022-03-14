<?php

namespace App\Jobs\Traits;

trait UsesCommandLine
{

    /**
     * @var string[]
     */
    private array $command;

    protected function initCommand(string ...$base): self
    {
        $this->command = [...$base];

        return $this;
    }

    protected function optionalParameter(string $name, mixed $value): self
    {
        if (!empty($value)) {
            $this->parameters($name, $value);
        }

        return $this;
    }

    protected function parameters(mixed ...$parameters): self
    {
        $this->command = [...$this->command, ...$parameters];

        return $this;
    }

    protected function booleanParameter(string $name, bool $value, string $true = 'yes', string $false = 'no'): self
    {
        return $this->parameters($name, $value ? $true : $false);
    }

    protected function conditionalParameter(string $name, mixed $value, bool $condition = true): self
    {
        if ($condition) {
            $this->parameters($name, $value);
        }

        return $this;
    }

    protected function flagParameter(string $name, bool $enabled = true): self
    {
        if ($enabled) {
            $this->parameters($name);
        }

        return $this;
    }

    protected function arrayParameter(string $name, array $value, bool $implode = false, string $separator = ','): self
    {
        if ($implode) {
            return $this->parameters($name, implode($separator, $value));
        }

        foreach ($value as $item) {
            if (!empty($item)) {
                $this->parameters($name, $item);
            }
        }

        return $this;
    }

    protected function command(): array
    {
        return $this->command;
    }

    protected static function commandStringToArray(string $command): array
    {
        return array_filter(
            array_map(static fn($x) => trim($x), str_getcsv(string: $command, separator: ' ')),
            static fn($x) => !empty($x)
        );
    }

    protected static function flattenCommandArray(array $command): array
    {
        return collect($command)->flatMap(fn($x) => static::commandStringToArray($x))->toArray();
    }

}